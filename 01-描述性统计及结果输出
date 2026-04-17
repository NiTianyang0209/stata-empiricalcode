**# 描述性统计 
sum Y X M $CV 
sum Y X M $CV, d 

* 导出描述性统计 
estpost sum Y X M $CV, d
*结果输出 
esttab using "描述性统计.rtf", ///
cells("count mean(fmt(3)) sd(fmt(3)) min(fmt(3)) p50(fmt(3)) max(fmt(3))") ///
noobs compress replace title(Descriptive statistics) // fmt(4)就是保留4位小数 
