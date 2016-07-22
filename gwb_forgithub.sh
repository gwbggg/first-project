#!/bin/bash
#该脚本用来从xml文件中获取对应标签的值。
#主要练习sed命令。grep 。和shell脚本执行的基本流程。
#本脚本不足：使用临时文件。如果设备中内存不足的情况。有可能会导致不能生成临时文件。
PATCH_CFG_BOARD_TYPE=()
function getNodeTypeByProductNameAndBoardType()
{
    local productname=$1
	local BoardTypename=$2
	local file_path=$3
	local file=${file_path##*/}
	local pdt_config_path=${file_path%/*}
	local Node_Type
	local NodeNum
	#获取到productName
	local Product_tmpname=$(grep -Eo "\<Product name=\".*\"" ${file_path} | awk -F\" '{print $2}')
	#先判断productname是否存在。
	if [ -z "${Product_tmpname}" ];
	then
	    return 1
	fi
	if echo "${Product_tmpname[@]}" | grep -w "${productname}" &> /dev/null;
	then
	#截取两个标签之间的内容输出到临时文件
	sed -n "/<Product name=\"${productname}\"/,/<\/Product>/p" ${file_path} >> ${pdt_config_path}/${productname}_BoardNodeConfig.tmp
	else
	rm *.tmp &> /dev/null
	fi
	local tmppath=${pdt_config_path}/${productname}_BoardNodeconfig.tmp
	local Board_tmpType=$(grep -Eo "\<BoardType type=\".*\"" ${tmppath} | awk -F\" '{print $2}')
	if [ -z "${Board_tmpType}" ]
	then
	    return 2
	fi
	if echo "${Board_tmpType[@]}" | grep -w "${BoardTypename}" &>/dev/null;
	then
	    sed -n "/<BoardType type=\"${BoardTypename}\"/,/<\/BoardType>/p" ${tmppath} >> ${pdt_config_path}/${BoardTypename}_BoardNodeconfig.tmp
	else
	    rm *.tmp
	    return 2
	fi
	local tmppath2=${pdt_config_path}/${BoardTypename}_BoardNodeconfig.tmp
	sed -n "/<NodeType/p>" ${tmppath2} >> ${pdt_config_path}/${BoardTypename}_Nodeconfig.tmp
	local tmppath3=${pdt_config_path}/${BoardTypename}_Nodeconfig.tmp
	while read line
	do
	    echo ${line} > ${pdt_config_path}/BoardgwbNodeconfig.tmp
		local tmppath4=${pdt_config_path}/BoardgwbNodeconfig.tmp
		Node_Type[NodeNum]=${grep -Eo "\<NodeType type=\".*\"" ${tmppath4} | awk -F\" '{print$2}'}
		Node_Type[NodeNum]=$((Node_Type[NodeNum]))
		((NodeNum++))
	done <${tmppath3}
	rm *.tmp
}

function getNodeTypeByPdtBoardMbOrLc()
{
    local NodeTypeTmp
	NodeTypeTmp=$(getNodeTypeByProductNameAndBoardType $1 $2 $3)
	local num=$?
	if [ $num -eq 1 ]
	then
	    echo ""
		return 1
	elif [ $num -eq 2 ]
	then
	    echo ""
		return 2
	fi
	echo "${NodeTypeTmp[*]}" >> lastResult_Node.tmp
}

function Patch_Main()
{
    local nodetypeall
	local MbOrLc=$3
	if [ !-n "$MbOrLc" ]
	then
	    echo ""
		exit 3
	fi
	if [ ! -n "PATCH_CFG_BOARD_TYPE" ]
	then
	   echo ""
	   exit 4
	fi
	for board in ${PATCH_CFG_BOARD_TYPE[@]};
	do
	    getNodeTypeByPdtBoardMbOrLc $1 $board $2 $3
		local num=$?
		if [ $num -eq 1 ]
		then
		    rm lastResult_Node.tmp &>/dev/null
			return 1
		elif [ $num -eq 2 ]
		then
		    rm lastResult_Node.tmp &>/dev/null
			return 2
		fi
	done
	if [ ${MbOrLc} == MBgwb_LCgwb ]
	then
	    echo "42" >> lastResult_Node.tmp
	elif [ ${MbOrLc} == MBgwb ]
	then
	    rm lastResult_Node.tmp &> /dev/null
		echo "42" >> lastResult_Node.tmp
	fi
	sed -i 's/*[][ ]*//g' lastResult_Node.tmp
	sed -i 's/[ ][ ]*/,/g' lastResult_Node.tmp
	sed -i ':a;N;s/\n/,/;t a;' lastResult_Node.tmp
	
	NodeTypeResult=$(sed -n '1p' lastResult_Node.tmp)
	echo "${NodeTypeResult}"
	export NodeTypeResult
	rm *.tmp $>/dev/null
}

Patch_Main $1 $2 $3






















































