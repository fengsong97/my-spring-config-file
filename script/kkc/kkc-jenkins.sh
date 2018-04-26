try {
        node('slave-maven') {
            def image_name = "$DOCKER_HUB_ADDRESS/${app_name}:${app_version}-${tag}"
            //def image_name = "docker.kanche.com/${app_name}:${app_version}-DEV"
            stage('checkout') {
                git branch: "$brans", credentialsId: 'oschine', url: "$GIT_URL/${app_name}.git"
            }
           
            stage('maven build') {
             //   sh "sed -i \'s/maven.kanche.com/maven.kkche.cn/\' pom.xml"
           //     sh "mvn -Dmaven.test.failure.ignore clean package"
                sh "mvn -Dmaven.test.failure.ignore clean package"
            }
        
            stage('push docker') {
                    sh "sudo docker build -t $image_name -f docker/Dockerfile ."
                    sh "sudo docker push $image_name"  
            }
        }
        node('slave-python') {
            def image_name = "$DOCKER_HUB_ADDRESS/${app_name}:${app_version}-${tag}"
            def domain_name = "${app_name}.local"
            switch(app_status) {
                case "update":
                    stage('blue-green') {
                        sh """python /home/jenkins/script/dev/${app_name}.py $app_name $image_name $tag "$domain_name" $cluster_api $app_version $app_status "$node" $nodes"""
                    }
                    break
                case "deploy":
                    stage('deploy') {
                        sh "python /home/jenkins/script/dev/DelApp.py $cluster_api $app_name $tag"
                        sh """python /home/jenkins/script/dev/${app_name}.py $app_name $image_name $tag "$domain_name" $cluster_api 1 $app_status "$node" $nodes"""
                    }
                    break
                default:
                    print 'Input error, please enter a value corresponding to update or deploy'
                    break
            }
            stage('check deploy'){
                sh "python /home/jenkins/script/dev/check_status.py $cluster_api $app_name $tag"
            }
        }
}   catch (e) {
        // If there was an exception thrown, the build failed
            currentBuild.result = "FAILED"
            throw e
        } finally {
        // Success or failure, always send notifications
        notifyBuild(currentBuild.result)
        }
def notifyBuild(String buildStatus = 'STARTED') {
    // build status of null means successful
    buildStatus = buildStatus ?: 'SUCCESSFUL'
  // Default values
  def subject = "Jenkins $tag ${buildStatus}: Job '${env.JOB_NAME}' (${env.BUILD_NUMBER})"
  def details = '''(本邮件是程序自动下发的，请勿回复！)<br/><hr/>

项目名称：$PROJECT_NAME<br/><hr/>

构建编号：$BUILD_NUMBER<br/><hr/>

构建状态：$BUILD_STATUS<br/><hr/>

触发原因：${CAUSE}<br/><hr/>

构建日志地址：<a href="${BUILD_URL}console">${BUILD_URL}console</a><br/><hr/>

构建地址：<a href="$BUILD_URL">$BUILD_URL</a><br/><hr/>

变更集:${JELLY_SCRIPT,template="html"}<br/><hr/>'''

  emailext (
      //attachLog: true,
      subject: subject,
      body: details,
      to: "xianming.chu@kanche.com,wenjun.zhi@kanche.com"
    )
}