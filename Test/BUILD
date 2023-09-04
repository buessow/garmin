load('//:monkey.bzl', 'monkeyc_binary')

filegroup(
  name = 'resources',
  srcs = glob(['resources*/**/*.xml']),
)

monkeyc_binary(
  name = 'Test', 
  manifest = 'manifest.xml',
  device = 'fenix7',
  resources = [':resources'],
  test = True,
  srcs = ['//Shared',
          '//Shared:Base',
          '//Shared:Scheduler',
	  '//TestLib:TestLib',
          'source/BackgroundSchedulerTest.mc',
          'source/DataTest.mc',
          'source/DateValuesTest.mc',
          'source/DeltaVarEncodedBufferTest.mc',
          'source/Main.mc',
          'source/UtilTest.mc',
	 ],
)
