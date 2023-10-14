load('//:monkey.bzl', 'monkeyc_binary')

filegroup(
  name = 'sources',
  srcs = glob(['source/*.mc']),
  visibility = ['//visibility:private'],
)

monkeyc_binary(
  name = 'GlucoseWidget', 
  jungles = 'monkey.jungle',
  srcs = ['//Shared', ':sources'],
  resources = glob(['resources*/**/*.xml'], exclude_directories=1, allow_empty=True),
)
