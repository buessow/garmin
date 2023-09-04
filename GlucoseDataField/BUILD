load('//:monkey.bzl', 'monkeyc_binary')

filegroup(
  name = 'resources',
  srcs = glob(['resources*/**/*.xml'], exclude_directories=1, allow_empty=True),
  visibility = ['//visibility:private'],
)

monkeyc_binary(
  name = 'edge1030', 
  manifest = 'manifest.xml',
  device = 'edge1030',
  resources = ['resources'],
  srcs = ['//Shared',
          '//Shared:Base',
	  '//Shared:Scheduler',
          'source/GlucoseDataFieldApp.mc',
          'source/GlucoseDataFieldView.mc',
          'source/HeartRateCollector.mc',
	 ],
)

monkeyc_binary(
  name = 'edge1030plus', 
  manifest = 'manifest.xml',
  device = 'edge1030plus',
  resources = glob(['resources/**/*.xml'], exclude_directories=1, allow_empty=True),
  srcs = ['//Shared',
          '//Shared:Base',
	  '//Shared:Scheduler',
          'source/GlucoseDataFieldApp.mc',
          'source/GlucoseDataFieldView.mc',
          'source/HeartRateCollector.mc',
	 ],
)

monkeyc_binary(
  name = 'edge530', 
  manifest = 'manifest.xml',
  device = 'edge530',
  resources = glob(['resources/**/*.xml'], exclude_directories=1, allow_empty=True),
  srcs = ['//Shared',
          '//Shared:Base',
	  '//Shared:Scheduler',
          'source/GlucoseDataFieldApp.mc',
          'source/GlucoseDataFieldView.mc',
          'source/HeartRateCollector.mc',
	 ],
)

monkeyc_binary(
  name = 'fenix5plus', 
  manifest = 'manifest.xml',
  device = 'fenix5plus',
  resources = glob(['resources/**/*.xml'], exclude_directories=1, allow_empty=True),
  srcs = ['//Shared',
          '//Shared:Base',
	  '//Shared:Scheduler',
          'source/GlucoseDataFieldApp.mc',
          'source/GlucoseDataFieldView.mc',
          'source/HeartRateCollector.mc',
	 ],
)

monkeyc_binary(
  name = 'fenix7', 
  manifest = 'manifest.xml',
  device = 'fenix7',
  resources = ['resources'],
  srcs = ['//Shared',
          '//Shared:Base',
	  '//Shared:Scheduler',
          'source/GlucoseDataFieldApp.mc',
          'source/GlucoseDataFieldView.mc',
          'source/HeartRateCollector.mc',
	 ],
)
