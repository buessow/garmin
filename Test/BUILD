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
  manifest = 'manifest.xml',
  resources = ['//Shared:Resources', ':resources'],
  test = True,
  srcs = ['//Shared',
       	  '//TestLib:TestLib',
          ':sources',
	 ],
)
