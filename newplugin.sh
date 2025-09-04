#!/bin/sh

read -p "Plugin name: " pname
read -p "Supported minecraft versions: " mcvers
read -p "Who are you: " uname
read -p "Description: " desc
read -p "Package name: " pack

git clone https://github.com/john200410/example-plugin "$pname" -q

sed -i "s/^plugin_name =.*/plugin_name = $pname/" "$pname/gradle.properties"
sed -i "s/^java_version =.*/java_version = 21/" "$pname/gradle.properties"

mcfirst=$(echo "$mcvers" | sed 's/[ ,].*//')
sed -i "s/^minecraft_version =.*/minecraft_version = $mcfirst/" "$pname/gradle.properties"

rm -rf "$pname/src/main/java/org" "$pname/src/main/resources/exampleplugin" "$pname/.git" "$pname/LICENSE"

mkdir -p "$pname/src/main/java/$uname/$pack"

json="$pname/src/main/resources/rusherhack-plugin.json"
url=""
classbase=$(echo "$pname" | sed -E 's/(^|-)([a-z])/\U\2/g')
mcjson=$(echo "$mcvers" | tr ', ' '\n' | awk NF | sed 's/^/"/;s/$/"/' | paste -sd, -)

jq --arg name "$uname" \
   --arg url "$url" \
   --arg class "$uname.$pack.$classbase" \
   --arg mcjson "[$mcjson]" \
   '.Authors = [$name] |
    .URL = $url |
    ."Plugin-Class" = $class |
    ."Minecraft-Versions" = ($mcjson|fromjson)' \
   "$json" > "$json.tmp" && mv "$json.tmp" "$json"

jq --arg desc "$desc" '.Description = $desc' "$json" > "$json.tmp" && mv "$json.tmp" "$json"

mainfile="$pname/src/main/java/$uname/$pack/$classbase.java"
cat > "$mainfile" <<EOF
package $uname.$pack;

import org.rusherhack.client.api.RusherHackAPI;
import org.rusherhack.client.api.plugin.Plugin;

public class $classbase extends Plugin {
	@Override
	public void onLoad() {
		this.getLogger().info("loaded $pname");
	}
	@Override
	public void onUnload() {
		this.getLogger().info("$pname unloaded!");
	}
}
EOF

echo "# $pname
### $desc" > "$pname/README.md"

echo -e "\nAll done! Project folder created at ./$pname"
