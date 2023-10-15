load('//:monkey.bzl', 'monkeyc_binary')

filegroup(
  name = 'resources',
  srcs = glob(['resources*/**/*.xml'], exclude_directories=1, allow_empty=True),
  visibility = ['//visibility:private'],
)

filegroup(
  name = 'sources',
  srcs = glob(['source/*.mc']),
  visibility = ['//visibility:private'],
)

monkeyc_binary(
  name = 'GlucoseDataField', 
  jungles = 'monkey.jungle',
  resources = ['//Shared:Resources', ':resources'],
  srcs = ['//Shared', ':sources'],
)
