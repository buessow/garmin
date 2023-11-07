load('//:monkey.bzl', 'monkeyc_binary')
load('//:monkey.bzl', 'monkeyc_package')

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
  manifest = 'manifest.xml',
  resources = ['//Shared:Resources', ':resources'],
  srcs = ['//Shared', ':sources'],
)

monkeyc_package(
  name = 'package', 
  jungles = 'monkey.jungle',
  manifest = 'manifest.xml',
  resources = [':resources'],
  srcs = [':sources'],
)
