* 异质性分析视角：https://zhuanlan.zhihu.com/p/666820415
* 组间系数检验做法一览：https://www.lianxh.cn/details/19.html
**# 异质性检验-组间系数差异检验 
bdiff, group(groupvar) model(reghdfe Y X $CV, ab(id year) vce(cluster clustervar)) reps(1000) bs first detail seed(12345678) //


  
