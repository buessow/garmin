monkeydo_script_tmpl = """\
#!/bin/bash
DST=/tmp/GARMIN/APPS
STATE=/tmp/com.garmin.connectiq
[ -d $STATE ] && rm -rf $STATE
mkdir -p $DST
echo `pwd`
cd {prg}
(cd /tmp; "connectiq") & #  > /dev/null 2>&1) &
while [ ! -d $DST ]; do echo waiting for $DST; sleep 1; done
sleep 5
cp -f {prg_device}.prg $DST/{prg}.prg
cp -f {prg_device}.prg.debug.xml $DST/{prg}.prg.debug.xml
"monkeydo" {prg_device}.prg {device} {test_flag}
killall simulator
"""

OPT = {
  'dbg': '1',
  'fastbuild': '2',
  'opt': '3pz',
}

def _monkeyc_binary_impl(ctx):
  developer_key = '/Users/robertbuessow/StudioProjects/developer_key'
  device = ctx.var['TARGET_CPU']
  prg = ctx.files.jungles[0].dirname
  prg_device = '%s_%s' % (ctx.attr.name, device)
  prg_file = ctx.actions.declare_file(prg_device + ".prg")
  outputs = [
      prg_file, 
      ctx.actions.declare_file(prg_device + ".prg.debug.xml")
  ]
  profile = ctx.var['COMPILATION_MODE'] == 'dbg'
  ctx.actions.run_shell(
    inputs = ctx.files.jungles + ctx.files.srcs + ctx.files.resources,
    outputs = outputs,
    progress_message = 'Building %s.prg' % ctx.attr.name,
    execution_requirements = { 'no-sandbox': 'True' },
    use_default_shell_env = True,
    command  = ' '.join([
        'monkeyc',
        '--jungles %s' % '\\;'.join([f.path for f in ctx.files.jungles]),
        '--output %s' % prg_file.path,
        '--private-key $(printenv DEVELOPER_KEY)', 
        '--device %s' % device,
        '--warn',
        '--optimization %s' % OPT[ctx.var['COMPILATION_MODE']],
        '--profile' if profile else '',
        '--unit-test' if ctx.attr.test else ''
    ])
  )
  monkeydo_script = ctx.actions.declare_file('%s-do.sh' % ctx.attr.name)
  monkeydo_script_content = monkeydo_script_tmpl.format(
    prg=prg,
    prg_device=prg_device,
    device=device,
    test_flag=' -t' if ctx.attr.test else '')
  ctx.actions.write(monkeydo_script, monkeydo_script_content, is_executable=True)
  return [DefaultInfo(runfiles=ctx.runfiles(files=outputs), executable=monkeydo_script)]

def _monkeyc_package_impl(ctx):
  developer_key = '/Users/robertbuessow/StudioProjects/developer_key'
  prg = ctx.files.jungles[0].dirname
  prg_file = ctx.actions.declare_file(prg + ".iq")
  outputs = [prg_file]
  ctx.actions.run_shell(
    inputs = ctx.files.jungles + ctx.files.srcs + ctx.files.resources,
    outputs = outputs,
    progress_message = 'Building %s.iq' % ctx.attr.name,
    execution_requirements = { 'no-sandbox': 'True' },
    use_default_shell_env = True,
    command  = ' '.join([
        'monkeyc',
        '--jungles %s' % '\\;'.join([f.path for f in ctx.files.jungles]),
        '--output %s' % prg_file.path,
        '--private-key $(printenv DEVELOPER_KEY)', 
        '--warn',
        '--optimization %s' % OPT[ctx.var['COMPILATION_MODE']],
        '--package-app',
        '--release',
    ])
  )
  return [DefaultInfo(runfiles=ctx.runfiles(files=outputs))]

monkeyc_binary = rule(
  implementation = _monkeyc_binary_impl,
  attrs = {
    'srcs': attr.label_list(mandatory=True, allow_files=['.mc']),
    'resources': attr.label_list(default=[], allow_files=True),
    'jungles': attr.label(mandatory=True, allow_single_file=True),
    'test': attr.bool(default=False),
  },
  executable = True,
)

monkeyc_package = rule(
  implementation = _monkeyc_package_impl,
  attrs = {
    'srcs': attr.label_list(mandatory=True, allow_files=['.mc']),
    'resources': attr.label_list(default=[], allow_files=True),
    'jungles': attr.label(mandatory=True, allow_single_file=True),
  },
  executable = False,
)

