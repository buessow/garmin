DEVELOPER_KEY ?= '$(HOME)/StudioProjects/developer_key'
device ?= fenix7
opt ?= 2
MONKEYC_FLAGS = --private-key $(DEVELOPER_KEY) --typecheck 2

.NOPARALELL:


shared_dep = Shared/source/*.mc Shared/resources/*/*

# Devices whose layout is generated rather than checked in. Generating is deliberately not part of
# building: the generator's output moves between versions, so a build would silently replace the
# layouts under test. Run `make layouts` when you want them (re)generated. Without the generated
# files a device falls back to its family layout (resources-rectangle-246x322 and -282x470), which
# builds fine but is not what these devices ship with.
df_auto_layout = edge530 edge540 edge830 edge840 edge1030 edge1030bontrager \
	edge1030plus edge1040 edge1050 edgeexplore2

# Generated the same way, but checked in rather than thrown away: these are meant to be hand-tuned
# in connectiq_x's editor (--preview --generate), which writes its adjustments to a
# layout-overrides.json beside the layout.xml and re-applies them on every regeneration. `clean`
# deliberately leaves them alone - wiping the directory would take the overrides with it.
df_editable_layout = vivoactive5 vivoactive6

.PHONY: layouts
layouts:
	java -jar Tools/connectiq_x-1.0-all.jar \
			--devices=/Users/robertbuessow/CIQ/Devices \
			--output=GlucoseDataField --generate $(df_auto_layout) $(df_editable_layout)

# Opens connectiq_x's editor on the checked-in layouts. --generate alongside --preview is what
# makes an edit stick: it saves the override and rewrites layout.xml as you go. Without it the
# window is read-only. e.g. `make layout-edit dev=vivoactive5`.
.PHONY: layout-edit
layout-edit: dev ?= $(firstword $(df_editable_layout))
layout-edit:
	java -jar Tools/connectiq_x-1.0-all.jar \
			--devices=/Users/robertbuessow/CIQ/Devices \
			--output=GlucoseDataField --preview --generate $(dev)

# Single device, e.g. `make GlucoseDataField/resources-edge840/layout.xml`.
GlucoseDataField/resources-edge%/layout.xml: Tools/connectiq_x-1.0-all.jar
	java -jar Tools/connectiq_x-1.0-all.jar \
			--devices=/Users/robertbuessow/CIQ/Devices \
			--output=GlucoseDataField --generate $(@:GlucoseDataField/resources-%/layout.xml=%)

%/resources/_version.xml: %/manifest.xml
	v=`xmlstarlet select --text --template --value-of '//iq:manifest/iq:application/@version' -n $<`; \
	echo "<strings><string id='Version'>$$v</string><string id='BuildTime'>`date -Iminutes`</string></strings>" > "$@"

%/source/_Version.mc: %/manifest.xml
	v=`xmlstarlet select --text --template --value-of '//iq:manifest/iq:application/@version' -n $<`; \
    t=`date -Iminutes`; \
    echo "T: $$t"; \
	echo "module BuildInfo { const VERSION = \"$$v\"; const BUILD_TIME = \"$$t\"; }" > "$@"

# %/resources*/* matches files sitting directly in a resource dir (resources-<device>/layout.xml)
# but only the *directory* for nested ones, and a directory's mtime doesn't change when a file
# inside it is edited - so %/resources*/*/* is needed too, or edits to e.g.
# resources-local/settings/properties.xml never trigger a rebuild.
resource_dep = %/resources*/* %/resources*/*/*

bin-$(device)/%.prg: %/monkey.jungle %/manifest.xml %/source/_Version.mc %/source/*.mc %/resources/_version.xml $(resource_dep) $(shared_dep)
	[ -d "$(@D)" ] || mkdir "$(@D)"
	monkeyc --jungle $< --output $@ $(MONKEYC_FLAGS) --optimization $(opt) --device $(device) $(test_flag)

# Optional per-app jungle applied after monkey.jungle when packaging, so an app can drop
# gitignored local-only resource dirs from the store build (see Roadbook/monkey-release.jungle).
# Recursively expanded: $< is only defined inside the recipe. Apps without one package unchanged.
release_jungle = $(wildcard $(<D)/monkey-release.jungle)
release_jungles = "$<$(if $(release_jungle),;$(release_jungle))"

# Data.fakeMode replays canned glucose values or a canned error instead of asking AAPS - handy in
# the simulator, but a store build that ships it shows made-up readings to someone dosing insulin.
# Only the .iq package is guarded; a device build is how the fake modes get used in the first place.
check_fake_mode = \
	grep -qE '^[[:space:]]*private var fakeMode as FakeMode = normal;' Shared/source/Data.mc || { \
		echo "Shared/source/Data.mc: fakeMode is not normal - refusing to package $@" >&2; \
		exit 1; \
	}

# `| test` is order-only: the suite runs (and a failure aborts the package) before any store build,
# but because `test` is .PHONY it would otherwise count as permanently newer than the target and
# force a repackage on every invocation. Order-only prerequisites are still built, they just don't
# feed into the up-to-date decision - which is exactly the gate wanted here.
bin/%.iq: %/monkey.jungle %/manifest.xml %/source/_Version.mc %/source/*.mc %/resources/_version.xml $(resource_dep) $(shared_dep) | test
	@$(check_fake_mode)
	[ -d "$(@D)" ] || mkdir "$(@D)"
	monkeyc --jungle $(release_jungles) --output $@ $(MONKEYC_FLAGS) --optimization 3pz --package-app --release

# RoadbookGlance is built from Roadbook's sources and resources - its own directory holds only the
# glance view and the AppBase subclass that returns it. The pattern rules above glob the target's
# own directory for sources and resources, so neither can match it; spelled out instead, with the
# shared inputs listed so an edit to Roadbook rebuilds this too.
roadbook_glance_dep = RoadbookGlance/monkey.jungle RoadbookGlance/manifest.xml \
	RoadbookGlance/source/_Version.mc RoadbookGlance/source/*.mc \
	Roadbook/source/*.mc Roadbook/resources/*/* $(shared_dep)

bin-$(device)/RoadbookGlance.prg: $(roadbook_glance_dep)
	[ -d "$(@D)" ] || mkdir "$(@D)"
	monkeyc --jungle RoadbookGlance/monkey.jungle --output $@ $(MONKEYC_FLAGS) \
		--optimization $(opt) --device $(device)

bin/RoadbookGlance.iq: $(roadbook_glance_dep) | test
	[ -d "$(@D)" ] || mkdir "$(@D)"
	monkeyc --jungle "RoadbookGlance/monkey.jungle;RoadbookGlance/monkey-release.jungle" \
		--output $@ $(MONKEYC_FLAGS) --optimization 3pz --package-app --release

GlucoseDataField: bin-$(device)/GlucoseDataField.prg
GlucoseWidget: bin-$(device)/GlucoseWidget.prg
GlucoseWatchFace: bin-$(device)/GlucoseWatchFace.prg
Roadbook: bin-$(device)/Roadbook.prg
# Same sources as Roadbook, built as a watch-app with a glance for the Edge generation that dropped
# widgets. device= must be one of those (edge540/550/840/850/1040/1050/explore2/mtb).
RoadbookGlance: bin-$(device)/RoadbookGlance.prg


.PHONY: test
test: test_flag = --unit-test
test: bin-$(device)/Test.prg
	connectiq $(device)
	sleep 2
	# monkeydo exits 1 even when every test passed, so its status says nothing and `make test`
	# could never succeed. The summary line is the actual verdict; tee keeps the run visible on
	# the terminal while the log is what gets checked.
	monkeydo bin-$(device)/Test.prg $(device) -t 2>&1 | tee bin-$(device)/test.log
	grep -qE '^PASSED \(passed=[0-9]+, failed=0, errors=0\)$$' bin-$(device)/test.log
	-killall simulator

.PHONY: %/run
%/run: %
	connectiq $(device)
	sleep 5
	monkeydo bin-$(device)/$(@D).prg $(device)
	# killall simulator

.PHONY: clean
clean:
	rm -rf bin-*
	rm -rf bin
	rm -f */resources/_version.xml
	rm -rf $(df_auto_layout:%=GlucoseDataField/resources-%)

