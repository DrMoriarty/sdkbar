# Sdkbar
Plugin manager for cocos2d-x with support sdkbox plugin format.

# Usage

`sdkbar --help|-h` show help page.

`sdkbar --list|-l` show installed plugins list

`sdkbar --list-box|-b` show all available plugins from SdkBox server.

`sdkbar --search|-s <word>` search plugins in SdkBox server matched to word.

`sdkbar --install|-i <plugin source>` install the plugin from local or remote source. You can use link to github repo, or link to zip or tar.gz archive.

`sdkbar --remove|-r <plugin name>` remove the installed plugin. 

`sdkbar --update|-u <plugin name` update the installed plugin. If the plugin have no updates (it's version number was not changed from the previous installation) the operation will be cancelled.

`sdkbar --updateall` update all installed plugins

`sdkbar --show <plugin name>` show detail information about an SdkBar plugin.

## Options

`--verbose` shows a lot of debug output

`--no-clean` don't clean install temp folder which usually is ~/.sdkbar/cache

`--variable|-v KEY=VALUE` set installation variable. Some plugins can use them to set up the plugin configuration.

`--force|-f` ignores dependency errors.

# Examples

Show plugins list:

```
bash-3.2$ sdkbar --list
Installed plugins:
sdkbar-utils 0.0.2
sdkbar-vk 0.0.3
sdkbar-ok 0.0.3
sdkbox-iap 2.3.15.2
```

Remove some plugin:
```
sdkbar --remove sdkbar-vk
```

Install local plugin:
```
sdkbar --install ~/projects/sdkbar-vk/ --variable APP_ID=NNNNNNN
```

Install remote plugin from the git repository:
```
sdkbar --install https://github.com/OrangeAppsRu/sdkbar-vk.git --variable APP_ID=NNNNNNN
```

Install remove plugin from the specified git commit:
```
sdkbar --install https://github.com/OrangeAppsRu/sdkbar-vk/archive/b415bc9c34565bb1ed54e028628bca71bc377ac1.zip --variable APP_ID=NNNNNNN
```

Install SDKBOX plugin:
```
sdkbar -i sdkboxads
```

Note: now you can update plugins with `--update` command only if them was installed from the git repository.
