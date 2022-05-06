# 部署华为云容器实例CCI样例

CCI部署有如下场景（下面场景workflow不同在部署cci action参数用法）：  
1.通过简单参数直接创建或者更新负载  
2.更加提供的yaml文件创建或者更新负载  

## **前置工作**
#### 用户相关信息获取
1) ak,sk[获取](https://support.huaweicloud.com/usermanual-ca/ca_01_0003.html?utm_campaign=ua&utm_content=ca&utm_term=console) 
2) region,project_id[获取](https://support.huaweicloud.com/usermanual-ca/ca_01_0001.html)   

#### 华为云容器实例 [Cloud Container Instance， CCI](https://support.huaweicloud.com/cci/index.html)
1) [服务权限管理设置](https://support.huaweicloud.com/usermanual-cci/cci_01_0074.html)
2) namespace [创建命名空间(如果不存在action自动创建 )](https://support.huaweicloud.com/qs-cci/cci_qs_0004.html)  
3) deployment [创建负载(如果不存在action自动创建 )](https://support.huaweicloud.com/qs-cci/cci_qs_0005.html)  
4) manifest：容器实例的工作负载yaml描述文件   
#### 容器镜像服务（[SoftWare Repository for Container，SWR](https://support.huaweicloud.com/swr/index.html)）    
1) [创建组织](https://support.huaweicloud.com/usermanual-swr/swr_01_0014.html)   
2) [授权管理](https://support.huaweicloud.com/usermanual-swr/swr_01_0072.html)
#### 参数说明
1) **env参数**

| Name          | Require | Default | Description |
| ------------- | ------- | ------- | ----------- |
| REGION_ID    |   true        |     cn-north-4    | region：华北-北京四	cn-north-4；华东-上海二	cn-east-2；华东-上海一	cn-east-3；华南-广州	cn-south-1|
| PROJECT_ID    |   true    |         | 项目ID，可以在[我的凭证](https://console.huaweicloud.com/iam/?locale=zh-cn#/mine/apiCredential)获取|
| ACCESS_KEY_ID    |   true    |         | 华为访问密钥即AK,需要在项目的setting--Secret--Actions下添加 ACCESSKEY 参数|
| ACCESS_KEY_SECRET    |   true    |         | 访问密钥即SK,需要在项目的setting--Secret--Actions下添加 ACCESSKEY SECRETACCESSKEY 两个参数|
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
#### 部署过程分为如下几个步骤
1) 代码检出  
2) 打包maven项目  
3) SWR容器镜像服务鉴权  
4) 制作并推送镜像到SWR  
5) 安装Kubectl工具  
6) 部署镜像到CCI
#### 代码检出 
```yaml
      - uses: actions/checkout@v2
```

#### 项目打包
```yaml
      - name: Build with Maven
        id: build-project
        run: mvn package -Dmaven.test.skip=true -U -e -X -B
```

#### SWR容器镜像服务鉴权
```yaml
      - name: Log in to HuaweiCloud SWR
        uses: huaweicloud/swr-login@v1
        with:
          region: ${{ env.REGION_ID }}
          access-key-id: ${{ secrets.ACCESSKEY }}
          access-key-secret: ${{ secrets.SECRETACCESSKEY }}
```

#### 制作并推送镜像到SWR
```yaml
      - name: Build, tag, and push image to HuaweiCloud SWR
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

#### 安装Kubectl工具
```yaml
      - name: Kubectl tool installer
        id: install-kubectl
        uses: Azure/setup-kubectl@v2.1
```

#### 部署镜像到CCI
##### 部署镜像到CCI场景一：通过简单参数直接创建或者更新负载
```yaml
      - name: deploy to cci
        uses: huaweicloud/deploy-cci-action@v1.0.1
        id: deploy-to-cci
        with:
          access_key: ${{ secrets.ACCESSKEY }}
          secret_key: ${{ secrets.SECRETACCESSKEY }}
          project_id: ${{env.PROJECT_ID}}
          region: ${{ env.REGION_ID }}
          namespace: action-namespace-name
          deployment: action-deployment-name
          image: ${{ steps.build-image.outputs.image }}
 ```    
##### 部署镜像到CCI场景二：更加提供的yaml文件创建或者更新负载
1) action 内容
```yaml
    - name: deploy to cci
      uses: huaweicloud/deploy-cci-action@v1.0.1
      id: deploy-to-cci
      with:
        access_key: ${{ secrets.ACCESSKEY }}
        secret_key: ${{ secrets.SECRETACCESSKEY }}
        project_id: ${{env.PROJECT_ID}}
        region: ${{ env.REGION_ID }}
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
1) github workflow yml地址: .github/workflows/github-actions-demo.yml  
2) manifest yml地址: deployment.yaml

