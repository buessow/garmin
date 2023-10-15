load('//:monkey.bzl', 'monkeyc_binary')

filegroup(
  name = 'resources',
  srcs = glob(['resources*/**/*.xml']),
)

filegroup(
  name = 'sources',
  srcs = glob(['source/*.mc']),
)

monkeyc_binary(
  name = 'Test', 
  jungles = 'monkey.jungle',
  resources = [':resources'],
  test = True,
  srcs = ['//Shared',
          '//Shared:Base',
          '//Shared:Scheduler',
       	  '//TestLib:TestLib',
          ':sources',
	 ],
)
