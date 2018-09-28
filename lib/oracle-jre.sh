# Detect product
j2se_detect_oracle_j2re=oracle_j2re_detect
oracle_j2re_detect() {
  j2se_release=0

  # 9: Update or GA release (jre-9.0.4_linux-x64_bin.tar.gz)
  if [[ $archive_name =~ jre-([0-9]+)(\.(([0-9]+)\.([0-9]+)))?_linux-(x64)_bin\.(tar\.gz) ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[3]}
    j2se_minor_version=${BASH_REMATCH[4]}
    j2se_revision_version=${BASH_REMATCH[5]}
    j2se_arch=${BASH_REMATCH[6]}
    if [[ $j2se_revision_version != "" ]]
    then
      j2se_version_name="$j2se_release Update $j2se_revision_version"
      j2se_version=${j2se_release}.${j2se_update}${revision}
    else
      j2se_version_name="$j2se_release GA"
      j2se_version=${j2se_release}${revision}
    fi
  fi

  # Update or GA release (jre-7u13-linux-x64.tar.gz)
  if [[ $archive_name =~ ^jre-([0-9]+)(u([0-9]+))?-linux-(i586|x64|amd64)\.(bin|tar\.gz) ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[3]}
    j2se_arch=${BASH_REMATCH[4]}
    if [[ $j2se_update != "" ]]
    then
      j2se_version_name="$j2se_release Update $j2se_update"
      j2se_version=${j2se_release}u${j2se_update}${revision}
    else
      j2se_version_name="$j2se_release GA"
      j2se_version=${j2se_release}${revision}
    fi
  fi

  # Early Access Release (jre-8-ea-bin-b103-linux-x64-15_aug_2013.tar.gz)
  if [[ $archive_name =~ ^jre-([0-9]+)(u([0-9]+))?-(ea|fcs)-bin-(b[0-9]+)-linux-(i586|x64|amd64).*\.(bin|tar\.gz) ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[3]}
    j2se_build=${BASH_REMATCH[5]}
    j2se_arch=${BASH_REMATCH[6]}
    if [[ $j2se_update != "" ]]
    then
      j2se_version_name="$j2se_release Update $j2se_update Early Access Release Build $j2se_build"
      j2se_version=${j2se_release}u${j2se_update}~ea-build-${j2se_build}${revision}
    else
      j2se_version_name="$j2se_release Early Access Release Build $j2se_build"
      j2se_version=${j2se_release}~ea-build-${j2se_build}${revision}
    fi
  fi

  if [[ $j2se_release > 0 ]]
  then
    j2se_priority=$((310 + $j2se_release - 1))
    j2se_expected_min_size=85 #Mb

    # check if the architecture matches
    let compatible=1

    case "${DEB_BUILD_ARCH:-$DEB_BUILD_GNU_TYPE}" in
      i386|i486-linux-gnu)
        if [[ "$j2se_arch" != "i586" ]]; then compatible=0; fi
        ;;
      amd64|x86_64-linux-gnu)
        if [[ "$j2se_arch" != "x64" && "$j2se_arch" != "amd64" ]]; then compatible=0; fi
        ;;
    esac

    if [[ $compatible == 0 ]]
    then
      echo "The archive $archive_name is not supported on the ${DEB_BUILD_ARCH} architecture"
      return
    fi


    cat << EOF

Detected product:
    Java(TM) Runtime Environment (JRE)
    Standard Edition, Version $j2se_version_name
    Oracle(TM)
EOF
    if read_yn "Is this correct [Y/n]: "; then
      j2se_found=true
      j2se_required_space=$(( $j2se_expected_min_size * 2 + 20 ))
      j2se_vendor="oracle"
      j2se_title="Java Platform, Standard Edition $j2se_release Runtime Environment"

      j2se_install=oracle_j2re_install
      j2se_remove=oracle_j2re_remove
      j2se_jinfo=oracle_j2re_jinfo
      j2se_control=oracle_j2re_control
      oracle_jre_bin_hl="java javaws keytool orbd pack200 rmid rmiregistry servertool tnameserv unpack200 policytool"
      oracle_jre_bin_jre="javaws policytool"
      oracle_no_man_jre_bin_jre="ControlPanel jcontrol"
      oracle_jre_lib_hl="jexec"

      # changes for oracle java 9 (only one arch)
      if [[ $j2se_release == 9 ]] || [[ $j2se_release == 10 ]]
      then
        oracle_jre_bin_hl=""
        oracle_jre_bin_jre=""
        oracle_no_man_jre_bin_jre=""
        oracle_jre_lib_hl=""
        oracle_bin_jre=""

        # the man pages say: 'a list of alternatives of the form jre|jre <name> <path>.'
        oracle_no_man_lib_jre="jexec"
        oracle_no_man_bin_jre="java javaws jcontrol keytool orbd pack200 policytool rmid rmiregistry servertool tnameserv unpack200 appletviewer extcheck idlj jaotc jar jarsigner javac javadoc javah javap javapackager jcmd jconsole jcontrol jdb jdeprscan jdeps jhat jhsdb ji jimage jinfo jjs jlink jmap jmc jmod jps jrunscript jsadebugd jshell jstack jstat jstatd jvisualvm jweblauncher native2ascii nfo policytool rmic schemagen serialver wsgen wsimport xjc"
      else
        oracle_no_man_lib_jre=""
        oracle_no_man_bin_jre=""
      fi

      j2se_package="$j2se_vendor-java$j2se_release-jre"
      j2se_run
    fi
  fi
}

oracle_j2re_install() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

install_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_hl
install_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_jre
install_no_man_alternatives $jvm_base$j2se_name/bin $oracle_no_man_jre_bin_jre
install_no_man_alternatives $jvm_base$j2se_name/lib $oracle_jre_lib_hl

plugin_dir="$jvm_base$j2se_name/lib/$DEB_BUILD_ARCH"
for b in $browser_plugin_dirs;do
    install_browser_plugin "/usr/lib/\$b/plugins" "libjavaplugin.so" "\$b-javaplugin.so" "\$plugin_dir/libnpjp2.so"
done

# No plugin for ARM architecture yet
if [ "${DEB_BUILD_ARCH:0:3}" != "arm" ]; then
plugin_dir="$jvm_base$j2se_name/jre/lib/$DEB_BUILD_ARCH"
# 9 has no arch dir
if [[ $j2se_release == 9 ]] || [[ $j2se_release == 10 ]]; then
plugin_dir="$jvm_base$j2se_name/lib"
fi
for b in $browser_plugin_dirs;do
    install_browser_plugin "/usr/lib/\$b/plugins" "libjavaplugin.so" "\$b-javaplugin.so" "\$plugin_dir/libnpjp2.so"
done
fi
EOF
}

oracle_j2re_remove() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

remove_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_hl
remove_alternatives $jvm_base$j2se_name/bin $oracle_jre_bin_jre
remove_alternatives $jvm_base$j2se_name/bin $oracle_no_man_jre_bin_jre
remove_alternatives $jvm_base$j2se_name/lib $oracle_jre_lib_hl

plugin_dir="$jvm_base$j2se_name/lib/$DEB_BUILD_ARCH"
for b in $browser_plugin_dirs;do
    remove_browser_plugin "\$b-javaplugin.so" "\$plugin_dir/libnpjp2.so"
done

# No plugin for ARM architecture yet
if [ "${DEB_BUILD_ARCH:0:3}" != "arm" ]; then
plugin_dir="$jvm_base$j2se_name/jre/lib/$DEB_BUILD_ARCH"
# 9 has no arch dir
if [[ $j2se_release == 9 ]] || [[ $j2se_release == 10 ]]; then
plugin_dir="$jvm_base$j2se_name/lib"
fi
for b in $browser_plugin_dirs;do
    remove_browser_plugin "\$b-javaplugin.so" "\$plugin_dir/libnpjp2.so"
done
fi
EOF
}

oracle_j2re_jinfo() {
    cat << EOF
name=$j2se_name
priority=${priority_override:-$j2se_priority}
section=main
EOF
    jinfos "hl" $jvm_base$j2se_name/bin/ $oracle_jre_bin_hl
    jinfos "jre" $jvm_base$j2se_name/bin/ $oracle_jre_bin_jre
    jinfos "jre" $jvm_base$j2se_name/bin/ $oracle_no_man_jre_bin_jre
    jinfos "hl" $jvm_base$j2se_name/lib/ $oracle_jre_lib_hl
    for b in $browser_plugin_dirs;do
        echo "plugin $b-javaplugin.so $jvm_base$j2se_name/lib/$DEB_BUILD_ARCH/libnpjp2.so"
    done
}

oracle_j2re_control() {
    j2se_control
    if [ "$create_cert_softlinks" == "true" ]; then
        depends="ca-certificates-java"
    fi
    for i in `seq 5 ${j2se_release}`;
    do
        provides_runtime="${provides_runtime} java${i}-runtime,"
        provides_headless="${provides_headless} java${i}-runtime-headless,"
    done
    cat << EOF
Package: $j2se_package
Architecture: $j2se_debian_arch
Depends: \${misc:Depends}, \${shlibs:Depends}, java-common, $depends
Recommends: netbase
Provides: java-virtual-machine, java-runtime, java2-runtime, $provides_runtime java-runtime-headless, java2-runtime-headless, $provides_headless java-browser-plugin
Description: $j2se_title
 The Java(TM) SE Runtime Environment contains the Java virtual machine,
 runtime class libraries, and Java application launcher that are
 necessary to run programs written in the Java programming language.
 It is not a development environment and does not contain development
 tools such as compilers or debuggers.  For development tools, see the
 Java SE Development Kit (JDK).
 .
 This package has been automatically created with java-package ($version).
EOF
}
