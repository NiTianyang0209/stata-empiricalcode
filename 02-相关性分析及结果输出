**# 相关性分析 
correlate Y X $CV

*结果输出
estpost correlate Y X $CV, matrix
esttab using "相关性分析.rtf", unstack not noobs compress nogaps ///
replace star(* 0.1 ** 0.05 *** 0.01) b(%8.3f) title(correlation coefficient matrix)
