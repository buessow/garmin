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
  name = 'GlucoseWatchFace', 
  jungles = 'monkey.jungle',
  resources = [':resources'],
  srcs = [':sources'],
)

monkeyc_binary(
  name = 'test', 
  jungles = 'monkey.jungle',
  resources = [':resources'],
  srcs = [':sources'],
  test = True,
)
