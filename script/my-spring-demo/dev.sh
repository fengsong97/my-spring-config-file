
# sh ~/myGit/my-spring-config-file/script/my-spring-demo/dev.sh my-spring-demo dev

echo "脚本开始执行"

dock_hub_address=hub.c.163.com/fengsong97
app_name=$1
app_version=0.1.0
tag=$2

image_name=${dock_hub_address}/${app_name}:${app_version}-${tag}
echo "===拼接的镜像名字为: "$image_name" ==="

if [ ! -d ./$app_name ];then
	echo "===${app_name} 文件夹不存在==="
else
	rm -rf ./$app_name
	echo "===${app_name} 文件夹存在,删除完毕==="
fi

echo "===git clone==="
git clone https://github.com/fengsong97/$app_name.git

echo "===进入 $app_name 文件夹==="
cd $app_name
git checkout $tag
git pull
git status

echo "===maven构建完成生成 "$app_name".jar 文件==="
mvn -Dmaven.test.failure.ignore clean package

echo "===停掉可能运行的镜像 ${image_name} ==="
docker kill $(docker ps | grep $image_name | cut -d" " -f1)

echo "===docker镜像构建完成生成==="
docker build -t $image_name -f docker/Dockerfile .


echo "===删掉 $app_name 文件夹==="
cd ..

rm -rf ./$app_name
echo "===删除 ${app_name} 文件夹完毕==="

# docker login -u {你的网易云邮箱账号或手机号码} -p {你的网易云密码} hub.c.163.com
# docker push $image_name 
# echo "===推送镜像 "$image_name" 到远程docker仓库==="
echo "===尝试运行镜像==="
docker run -d -p  8081:8081 $image_name
echo "===镜像 ${image_name} 启动完成，请访问==="





