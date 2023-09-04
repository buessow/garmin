monkeydo_script_tmpl = """\
#!/bin/bash
DST=/tmp/GARMIN/APPS
STATE=/tmp/com.garmin.connectiq
[ -d $STATE ] && rm -rf $STATE
mkdir -p $DST
echo `pwd`
cd {prg}
(cd /tmp; {connectiq_path}/simulator > /dev/null 2>&1) &
while [ ! -d $DST ]; do echo waiting for $DST; sleep 1; done
cp -f {prg_device}.prg $DST/{prg}.prg
cp -f {prg_device}.prg.debug.xml $DST/{prg}.prg.debug.xml
{connectiq_path}/monkeydo {prg_device}.prg {device} {test_flag}
killall simulator
"""

def _monkeyc_binary_impl(ctx):
  developer_key = '/home/buessow/source/developer_key'
  connectiq_path = '/home/buessow/.Garmin/ConnectIQ/sdk/bin'
  prg = ctx.files.manifest[0].dirname
  prg_device = '%s_%s' % (prg, ctx.attr.name)
  prg_file = ctx.actions.declare_file(prg_device + ".prg")
  outputs = [
      prg_file, 
      ctx.actions.declare_file(prg_device + ".prg.debug.xml")
  ]
  ctx.actions.run_shell(
    inputs = ctx.files.manifest + ctx.files.srcs + ctx.files.resources,
    outputs = outputs,
    progress_message = 'Building %s.prg' % ctx.attr.name,
    execution_requirements = {
      'no-sandbox': 'True',
    },
    command  = ' '.join([
        '/opt/android-studio/jbr/bin/java',
	'-classpath %s/monkeybrains.jar' % connectiq_path,
	'com.garmin.monkeybrains.Monkeybrains',
	'--output %s' % prg_file.path,
        # '--jungles %s' % '\\;'.join([f.path for f in ctx.files.jungles]),
	'--manifest %s' % ctx.files.manifest[0].path,
	'--private-key %s' % developer_key, 
	' '.join(['--rez %s' % r.path for r in ctx.files.resources]),
	'--device %s' % ctx.attr.device,
	'--warn',
	'--unit-test' if ctx.attr.test else '',
	' '.join([s.path for s in ctx.files.srcs])
    ])
  )
  monkeydo_script = ctx.actions.declare_file('%s-do.sh' % ctx.attr.name)
  monkeydo_script_content = monkeydo_script_tmpl.format(
    connectiq_path=connectiq_path,
    prg=prg,
    prg_device=prg_device,
    device=ctx.attr.device,
    test_flag=' -t' if ctx.attr.test else '')
  ctx.actions.write(monkeydo_script, monkeydo_script_content, is_executable=True)

  return [DefaultInfo(runfiles=ctx.runfiles(files=outputs), executable=monkeydo_script)]

monkeyc_binary = rule(
  implementation = _monkeyc_binary_impl,
  attrs = {
    'srcs': attr.label_list(mandatory=True, allow_files=['.mc']),
    'resources': attr.label_list(default=[], allow_files=True),
    'manifest': attr.label(mandatory=True, allow_single_file=True),
    'device': attr.string(mandatory=True),
    'test': attr.bool(default=False),
  },
  executable = True,
)

