# Last Update: 2018-02-07
# Author: Gloomy Sunday

Tag_Version="$1"

if [${Tag_Version} = ""]; then 
	echo "You Need Input A Tag Version"
	exit 1
else
	echo "\nSubmit Verson: ${Tag_Version}\n"
	File_Path=$(cd `dirname $0`; pwd)
	Module_Path=${File_Path%/*}
	Module_File=`find $Module_Path -name *.podspec`
	Module_Code_Path="${Module_Path}/Example"
	Module_Name="${Module_File##*/}"
	Module_Name="${Module_Name%.*}"
	Old_Version="$(grep -r 's.version* ' ${Module_File} |awk -F = '{print $2}')"

	# 1.更新 jazzy documents
    echo "Begin Generate jazzy Document...."
	echo $(cd ${Module_Code_Path}; jazzy -m ${Module_Name} -x -workspace,${Module_Name}.xcworkspace,-scheme,${Module_Name} -c -a Gloomy.Sunday -u https://github.com/GloomySunday049 -g https://github.com/orgs/Sky-And-Hammer -o ${Module_Path}/docs --min-acl internal)
	echo "\nGit Commit For Document Updated "
	echo $(cd ${Module_Path};git add .; git commit -m "Updated: code documents updated")

	# # # 2.更新 .podspec 版本号
	echo "\nBegin Update Podspec Version...."
	echo $(sed -i "" "s/${Old_Version}/ '${Tag_Version}'/g" ${Module_File})
	echo "\nGit Commit For Podspec Updated"
	echo $(cd ${Module_Path};git add .; git commit -m "Updated: Podspec Version Updated")



	# 3.GIT PUSH & GIT TAG PUSH
   echo "\nGit Push...."
   echo $(cd ${Module_Path}; git push)
   echo "\nAdd Tag...."
   echo $(cd ${Module_Path};git tag -a ${Tag_Version} -m 'Release Version For Cocoapods')
   echo "\nGit Push Tag...."
   echo $(cd ${Module_Path}; git push origin ${Tag_Version})

   # # 4. Thunk to Cocoapods
   echo "\n Cocoapods Push..."
   echo $(cd ${Module_Path}; pod trunk push --verbose ${Module_File})

	echo "\nSuccess...."
fi
