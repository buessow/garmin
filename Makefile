DEVELOPER_KEY ?= '$(HOME)/StudioProjects/developer_key'
device ?= fenix7
opt ?= 2
MONKEYC_FLAGS = --private-key $(DEVELOPER_KEY) --typecheck 2

.NOPARALELL:


shared_dep = Shared/source/*.mc Shared/resources/*/* .df_auto_layout

df_auto_layout = edge530 edge830 edge1030 edge1030plus edgeexplore2
.df_auto_layout: Tools/connectiq_x-1.0-all.jar
	java -jar Tools/connectiq_x-1.0-all.jar \
			--devices=/Users/robertbuessow/CIQ/Devices \
			--output=GlucoseDataField $(df_auto_layout)
	touch .df_auto_layout

GlucoseDataField/resources-edge%/layout.xml: Tools/connectiq_x-1.0-all.jar
	java -jar Tools/connectiq_x-1.0-all.jar \
			--devices=/Users/robertbuessow/CIQ/Devices \
			--output=GlucoseDataField $(@:GlucoseDataField/resources-%/layout.xml=%)

%/resources/_version.xml: %/manifest.xml
	v=`xmlstarlet select --text --template --value-of '//iq:manifest/iq:application/@version' -n $<`; \
	echo "<strings><string id='Version'>$$v</string><string id='BuildTime'>`date -Iminutes`</string></strings>" > "$@"

%/source/_Version.mc: %/manifest.xml
	v=`xmlstarlet select --text --template --value-of '//iq:manifest/iq:application/@version' -n $<`; \
    t=`date -Iminutes`; \
    echo "T: $$t"; \
	echo "module BuildInfo { const VERSION = \"$$v\"; const BUILD_TIME = \"$$t\"; }" > "$@"

bin-$(device)/%.prg: %/monkey.jungle %/manifest.xml %/source/_Version.mc %/source/*.mc %/resources/_version.xml %/resources*/* $(shared_dep)
	[ -d "$(@D)" ] || mkdir "$(@D)"
	monkeyc --jungle $< --output $@ $(MONKEYC_FLAGS) --optimization $(opt) --device $(device) $(test_flag)

bin/%.iq: %/monkey.jungle %/manifest.xml %/source/_Version.mc %/source/*.mc %/resources/_version.xml %/resources*/* $(shared_dep)
	[ -d "$(@D)" ] || mkdir "$(@D)"
	monkeyc --jungle $< --output $@ $(MONKEYC_FLAGS) --optimization 3pz --package-app --release

GlucoseDataField: bin-$(device)/GlucoseDataField.prg
GlucoseWidget: bin-$(device)/GlucoseWidget.prg
GlucoseWatchFace: bin-$(device)/GlucoseWatchFace.prg

.PHONY: test
test: test_flag = --unit-test
test: bin-$(device)/Test.prg
	connectiq $(device)
	sleep 2
	monkeydo bin-$(device)/Test.prg $(device) -t
	killall simulator

.PHONY: %/run
%/run: %
	connectiq $(device)
	sleep 5
	monkeydo bin-$(device)/$(@D).prg $(device)
	killall simulator

.PHONY: clean
clean:
	rm -rf bin-*
	rm -rf bin
	rm -f */resources/_version.xml
	rm -f .df_auto_layout
	rm -rf $(df_auto_layout:%=GlucoseDataField/resources-%)

