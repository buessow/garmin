load('//:monkey.bzl', 'monkeyc_binary')
load('//:monkey.bzl', 'monkeyc_package')

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
          'source/Time.mc',
	 ],
)

monkeyc_binary(
  name = 'GlucoseWatchFace', 
  jungles = 'monkey.jungle',
  manifest = 'manifest.xml',
  resources = [':resources'],
  srcs = [':sources'],
)

monkeyc_binary(
  name = 'test', 
  jungles = 'monkey.jungle',
  manifest = 'manifest.xml',
  resources = [':resources'],
  srcs = [':sources'],
  test = True,
)

monkeyc_package(
  name = 'package', 
  jungles = 'monkey.jungle',
  manifest = 'manifest.xml',
  resources = [':resources'],
  srcs = [':sources'],
)

