load('//:monkey.bzl', 'monkeyc_binary')

filegroup(
  name = 'resources',
  srcs = glob(['resources*/**/*.xml']),
)

filegroup(
  name = 'sources',
  srcs = ['//Shared',
          '//Shared:Arrays',
	  'source/InputHandler.mc',
	  'source/NearPeaksGlanceView.mc',
	  'source/NearPeaksWidgetApp.mc',
	  'source/NearPeaksWidgetView.mc',
	  'source/OverpassLookup.mc',
	 ],
)
