{ shadowCmd, terminalCmd }:

''
<?xml version="1.0" encoding="UTF-8"?>

<openbox_menu xmlns="http://openbox.org/3.4/menu">

    <menu id="root-menu" label="ShadowOS">
        <separator label="Applications" />

        <item label="Shadow">
            <action name="Execute">
                <command>${shadowCmd}</command>
            </action>
        </item>

        <separator label="Configurations" />

        <item label="Sound">
            <action name="Execute">
                <command>pavucontrol</command>
            </action>
        </item>

        <separator label="System" />
        <item label="Terminal">
            <action name="Execute">
                <command>${terminalCmd}</command>
            </action>
        </item>

        <separator />

        <menu id="exit-menu" label="Exit">
            <item label="Log Out">
                <action name="Execute">
                    <command>openbox --exit</command>
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
