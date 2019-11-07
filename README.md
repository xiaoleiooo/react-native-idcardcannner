###### Now coding...,wait please



#### iOS


link


1、node_modules/react-native-idcardcannner/ios/RNIDcardScanner/libexidcard/dicts/zocr0.lib复制到主工程，并添加

2、复制idcard_front_head.png到主工程，并添加文件

3、在你的项目的Info.plist文件中，添加权限描述（Key   Value）

Privacy - Camera Usage Description 是否允许访问相机

Privacy - Photo Library Usage Description 是否允许访问相册


4、运行程序，可能会报 ENABLE_BITCODE 错误：
[](https://raw.githubusercontent.com/zhongfenglee/IDCardRecognition/master/Screenshot/ENABLE_BITCODE%20Error%20%E8%A7%A3%E5%86%B3%E6%96%B9%E6%B3%95.png)