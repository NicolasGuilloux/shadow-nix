{ lib, writeText, openbox, menu }:

let
  menuItem = (name: value: ''
    <item label="${name}">
        <action name="Execute">
            <command>${value}</command>
        </action>
    </item>
  '');
in writeText "obconfig.xml" ''
  <?xml version="1.0" encoding="UTF-8"?>

  <openbox_menu xmlns="http://openbox.org/3.4/menu">
    <menu id="root-menu" label="ShadowOS">
      <separator label="Applications" />
      
      ${lib.strings.concatStringsSep "\n" (lib.attrsets.mapAttrsToList menuItem menu)}

      <separator />

      <menu id="exit-menu" label="Exit">
        <item label="Log Out">
          <action name="Execute">
            <command>${openbox}/bin/openbox --exit</command>
          </action>
        </item>

        <item label="Shutdown">
          <action name="Execute">
            <command>systemctl poweroff</command>
          </action>
        </item>

        <item label="Restart">
          <action name="Execute">
            <command>systemctl reboot</command>
          </action>
        </item>
      </menu>
    </menu>
  </openbox_menu>
''
