load('//:monkey.bzl', 'monkeyc_binary')

filegroup(
  name = 'sources',
  srcs = ['//Shared',
          '//Shared:Graph',
	  'source/GlucoseGlance.mc',
	  'source/GlucoseWidgetApp.mc',
	  'source/GlucoseWidgetView.mc',
	  'source/InputHandler.mc',
	  'source/Messenger.mc',
	 ],
)

monkeyc_binary(
  name = 'fenix7', 
  manifest = 'manifest.xml',
  device = 'fenix7',
  srcs = [':sources'],
  resources = glob(['resources/**/*.xml'], exclude_directories=1, allow_empty=True) +
              glob(['resources-round-260x260/**/*.xml'], exclude_directories=1, allow_empty=True),
)

monkeyc_binary(
  name = 'edge1030', 
  manifest = 'manifest.xml',
  device = 'edge1030',
  srcs = [':sources'],
  resources = glob(['resources/**/*.xml'], exclude_directories=1, allow_empty=True) +
              glob(['resources-rectangle-282x470/**/*.xml'], exclude_directories=1, allow_empty=True),
)

monkeyc_binary(
  name = 'edge1030plus', 
  manifest = 'manifest.xml',
  device = 'edge1030plus',
  srcs = [':sources'],
  resources = glob(['resources/**/*.xml'], exclude_directories=1, allow_empty=True) +
              glob(['resources-rectangle-282x470/**/*.xml'], exclude_directories=1, allow_empty=True),
)
