load('//:monkey.bzl', 'monkeyc_binary')

filegroup(
  name = 'resources',
  srcs = glob(['resources*/**/*.xml']),
)

filegroup(
  name = 'sources',
  srcs = ['//Shared',
          '//Shared:Graph',
          '//Shared:Scheduler',
          'source/GlucoseWatchFaceApp.mc',
          'source/GlucoseWatchFaceView.mc',
	 ],
)

monkeyc_binary(
  name = 'fenix5plus', 
  manifest = 'manifest.xml',
  device = 'fenix5plus',
  resources = [':resources'],
  srcs = [':sources'],
)

monkeyc_binary(
  name = 'fenix7', 
  manifest = 'manifest.xml',
  device = 'fenix7',
  resources = [':resources'],
  srcs = [':sources'],
)
