# 部署华为云容器实例CCI Workflow样例
**本READEME指导是基于action: [Huawei Cloud CCI Deoloy](https://github.com/marketplace/actions/huawei-cloud-cci-deoloy)使用华为云容器实例CCI的workflows样例**    

CCI部署有如下场景（下面场景workflow不同在部署cci action参数用法）：  
1.通过简单参数直接创建或者更新负载  
2.更加提供的yaml文件创建或者更新负载  

## **前置工作**
### 1.鉴权认证
推荐使用[huaweicloud/auth-action](https://github.com/huaweicloud/auth-action)进行华为云部署容器实例的鉴权认证。
```yaml
    - name: Authenticate to Huawei Cloud
      uses: huaweicloud/auth-action@v1.0.0
      with: 
          access_key_id: ${{ secrets.ACCESSKEY }} 
          secret_access_key: ${{ secrets.SECRETACCESSKEY }}
          region: '<region>'
          project_id: '<project_id>'
```
### 2.华为云容器实例 [Cloud Container Instance， CCI](https://support.huaweicloud.com/cci/index.html)
1) [服务权限管理设置](https://support.huaweicloud.com/usermanual-cci/cci_01_0074.html)
2) namespace [创建命名空间(如果不存在action自动创建 )](https://support.huaweicloud.com/qs-cci/cci_qs_0004.html)  
3) deployment [创建负载(如果不存在action自动创建 )](https://support.huaweicloud.com/qs-cci/cci_qs_0005.html)  
4) manifest：容器实例的工作负载yaml描述文件   
### 3.容器镜像服务（[SoftWare Repository for Container，SWR](https://support.huaweicloud.com/swr/index.html)）    
1) [创建组织](https://support.huaweicloud.com/usermanual-swr/swr_01_0014.html)   
2) [授权管理](https://support.huaweicloud.com/usermanual-swr/swr_01_0072.html)
### 参数说明
1) **env参数**

| Name          | Require | Default | Description |
| ------------- | ------- | ------- | ----------- |
| REGION_ID    |   false        |     cn-north-4    | region：华北-北京四	cn-north-4；华东-上海二	cn-east-2；华东-上海一	cn-east-3；华南-广州	cn-south-1。如果使用华为云统一鉴权[huaweicloud/auth-action](https://github.com/huaweicloud/auth-action)可以不填写改参数。|
| PROJECT_ID    |   false    |         | 项目ID。如果使用华为云统一鉴权[huaweicloud/auth-action](https://github.com/huaweicloud/auth-action)可以不填写改参数。|
| ACCESS_KEY_ID    |   false    |         | 华为访问密钥即AK,需要在项目的setting--Secret--Actions下添加 ACCESSKEY 参数。如果使用华为云统一鉴权[huaweicloud/auth-action](https://github.com/huaweicloud/auth-action)可以不填写改参数|
| ACCESS_KEY_SECRET    |   false    |         | 访问密钥即SK,需要在项目的setting--Secret--Actions下添加SECRETACCESSKEY 两个参数。如果使用华为云统一鉴权[huaweicloud/auth-action](https://github.com/huaweicloud/auth-action)可以不填写改参数|
| SWR_ORGANIZATION    |   true    |         | SWR 组织名|
| IMAGE_NAME    |   true    |         | 镜像名称,用户根据自己镜像命名|  
2) **huaweicloud/deploy-cci-action参数**  

| Name          | Require | Default | Description |
| ------------- | ------- | ------- | ----------- |
| namespace    |   true         |         | CCI命名空间|
| deployment    |   true         |         | CCI负载名称|
| image    |   true         |         | 镜像地址，如1) [swr镜像中心](https://console.huaweicloud.com/swr/?agencyId=66af5f8d4b84416785817649d667a396&region=cn-north-4&locale=zh-cn#/app/swr/huaweiOfficialList)：nginx:latest;  2) swr[我的镜像](https://console.huaweicloud.com/swr/?agencyId=66af5f8d4b84416785817649d667a396&region=cn-north-4&locale=zh-cn#/app/warehouse/list):swr.cn-north-4.myhuaweicloud.com/demo/demo:v1.1|
| manifest    |   false    |         | 负载deployment描述yaml文件[Deployment](https://support.huaweicloud.com/devg-cci/cci_05_0005.html)|  



## **部署cci样例workflow**
### 部署过程分为如下几个步骤
一、代码容器构建build
1) 代码检出  
2) 打包maven项目  
3) SWR容器镜像服务鉴权  
4) 制作并推送镜像到SWR  
  
二、部署容器实例deploy
1) 华为云统一鉴权
2) 安装Kubectl工具  
3) 部署镜像到CCI
### 代码容器构建build-代码检出 
```yaml
      - uses: actions/checkout@v2
```

### 代码容器构建build-项目打包
```yaml
      - name: Build with Maven
        id: build-project
        run: mvn package -Dmaven.test.skip=true -U -e -X -B
```

### 代码容器构建build-SWR容器镜像服务鉴权
```yaml
      - name: Log in to Huawei Cloud SWR
        uses: huaweicloud/swr-login@v1
        with:
          region: ${{ env.REGION_ID }}
          access-key-id: ${{ secrets.ACCESSKEY }}
          access-key-secret: ${{ secrets.SECRETACCESSKEY }}
```

### 代码容器构建build-制作并推送镜像到SWR
```yaml
      - name: Build, Tag, and Push Image to Huawei Cloud SWR
        id: build-image
        env:
          SWR_REGISTRY: swr.${{ env.REGION_ID }}.myhuaweicloud.com
          SWR_ORGANIZATION: ${{ env.SWR_ORGANIZATION }}
          IMAGE_TAG: ${{ github.sha }}
          IMAGE_NAME: ${{ env.IMAGE_NAME }}
        run: |
          docker build -t $SWR_REGISTRY/$SWR_ORGANIZATION/$IMAGE_NAME:$IMAGE_TAG .
          docker push $SWR_REGISTRY/$SWR_ORGANIZATION/$IMAGE_NAME:$IMAGE_TAG
          echo "::set-output name=image::$SWR_REGISTRY/$SWR_ORGANIZATION/$IMAGE_NAME:$IMAGE_TAG"
```
### 部署容器实例deploy-华为云统一鉴权
```yaml
      - name: Authenticate to Huawei Cloud
        uses: huaweicloud/auth-action@v1.0.0
        with: 
            access_key_id: ${{ secrets.ACCESSKEY }} 
            secret_access_key: ${{ secrets.SECRETACCESSKEY }}
            region: ${{ env.REGION_ID }}
            project_id: ${{env.PROJECT_ID}}
```
### 部署容器实例deploy-安装Kubectl工具
```yaml
      - name: Kubectl Tool Installer
        id: install-kubectl
        uses: Azure/setup-kubectl@v2.1
```

### 部署容器实例deploy-部署镜像到CCI
#### 部署镜像到CCI场景一：通过简单参数直接创建或者更新负载
```yaml
      - name: Deploy to CCI
        uses: huaweicloud/deploy-cci-action@v1.0.3
        id: deploy-to-cci
        with:
          namespace: action-namespace-name
          deployment: action-deployment-name
          image: ${{ steps.build-image.outputs.image }}
 ```    
#### 部署镜像到CCI场景二：更加提供的yaml文件创建或者更新负载
1) action 内容
```yaml
    - name: Deploy to CCI
      uses: huaweicloud/deploy-cci-action@v1.0.3
      id: deploy-to-cci
      with:
        namespace: action-namespace-name
        deployment: action-deployment-name
        image: ${{ steps.build-image.outputs.image }}
        manifest: ./deployment.yml
```

2) yaml文件manifest内容  
以下示例为一个名为cci-deployment的Deployment负载，负载在命名空间是cci-namespace-70395701，使用swr.cn-north-4.myhuaweicloud.com/namespace/demo:v1.1t镜像创建两个Pod，每个Pod占用500m core CPU、1G内存。

```yaml
apiVersion: apps/v1      # 注意这里与Pod的区别，Deployment是apps/v1而不是v1
kind: Deployment         # 资源类型为Deployment
metadata:
  name: cci-deployment            # 必填,Deployment的名称即是负载的名称
spec:
  replicas: 2            # Pod的数量，Deployment会确保一直有2个Pod运行         
  selector:              # Label Selector
    matchLabels:
      app: cci-deployment  # Deployment的名称即是负载的名称
  template:              # Pod的定义，用于创建Pod，也称为Pod template
    metadata:
      labels:
        app: cci-deployment  # Deployment的名称即是负载的名称
    spec:
      containers:
      - image: swr.cn-north-4.myhuaweicloud.com/namespace/demo:v1.1  # 镜像地址,传入参数image会将次镜像地址替换
        name: container-0
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 500m
            memory: 1024Mi
          requests:
            cpu: 500m
            memory: 1024Mi
      imagePullSecrets:           # 拉取镜像使用的证书，必须为imagepull-secret
      - name: imagepull-secret
```
备注：  
1) github workflow yml地址:[.github/workflows/deploy-cci-demo.yml](.github/workflows/deploy-cci-demo.yml)
2) manifest yml地址: [deployment.yaml](deployment.yaml)