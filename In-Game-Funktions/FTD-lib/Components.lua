local I = {}

local BlockInfo = {
    Valid = true,
    Position = Vector3(0,0,0),
    LocalPosition = Vector3(0,0,0),
    Forwards = Vector3(0,0,1),
    LocalForwards = Vector3(0,0,0),
    Rotation = Quaternion(0,0,0,1),
    LocalRotation = Quaternion(0,0,0,1),
    CenterSubConstructIdentifier = 0,
    CustomName = "CustomName"
}

function I:Component_GetCount(type)
    return 0
end

function I:Component_GetLocalPosition(type,index)
    return Vector3(0,0,0)
end

function I:Component_GetBlockInfo(type,index)
    return BlockInfo
end

function I:Component_GetBoolLogic(type, blockIndex)
    return true
end

function I:Component_GetBoolLogic_1(type, blockIndex, propertyIndex)
    return true
end

function I:Component_SetBoolLogic(type,index,bool)
end

function I:Component_SetBoolLogic_1(type, blockIndex, propertyIndex1, bool1)
end

function I:Component_SetBoolLogic_2(type, blockIndex, propertyIndex1, bool1, propertyIndex2, bool2)
end

function I:Component_SetBoolLogic_3(type, blockIndex, propertyIndex1, bool1, propertyIndex2, bool2, propertyIndex3, bool3)
end

function I:Component_GetFloatLogic(type, blockIndex)
    return 0.0
end

function I:Component_GetFloatLogic_1(type, blockIndex, propertyIndex)
    return 0.0
end

function I:Component_SetFloatLogic(type,index,float)
end

function I:Component_SetFloatLogic_1(type, blockIndex, propertyIndex1, float1)
end

function I:Component_SetFloatLogic_2(type, blockIndex, propertyIndex1, float1, propertyIndex2, float2)
end

function I:Component_SetFloatLogic_3(type, blockIndex, propertyIndex1, float1, propertyIndex2, float2, propertyIndex3, float3)
end

function I:Component_GetIntLogic(type, blockIndex)
    return 0
end

function I:Component_GetIntLogic_1(type, blockIndex, propertyIndex)
    return 0
end

function I:Component_SetIntLogic(type,index,int)
end

function I:Component_SetIntLogic_1(type, blockIndex, propertyIndex1, int1)
end

function I:Component_SetIntLogic_2(type, blockIndex, propertyIndex1, int1, propertyIndex2, int2)
end

function I:Component_SetIntLogic_3(type, blockIndex, propertyIndex1, int1, propertyIndex2, int2, propertyIndex3, int3)
end

function I:Component_SetBoolLogicAll(type, bool)
end

function I:Component_SetBoolLogicAll_1(type, propertyIndex1, bool1)
end

function I:Component_SetBoolLogicAll_2(type, propertyIndex1, bool1, propertyIndex2, bool2)
end

function I:Component_SetBoolLogicAll_3(type, propertyIndex1, bool1, propertyIndex2, bool2, propertyIndex3, bool3)
end

function I:Component_SetFloatLogicAll(type, float)
end

function I:Component_SetFloatLogicAll_1(type, propertyIndex1, float1)
end

function I:Component_SetFloatLogicAll_2(type, propertyIndex1, float1, propertyIndex2, float2)
end

function I:Component_SetFloatLogicAll_3(type, propertyIndex1, float1, propertyIndex2, float2, propertyIndex3, float3)
end

function I:Component_SetIntLogicAll(type, int)
end

function I:Component_SetIntLogicAll_1(type, propertyIndex1, int1)
end

function I:Component_SetIntLogicAll_2(type, propertyIndex1, int1, propertyIndex2, int2)
end

function I:Component_SetIntLogicAll_3(type, propertyIndex1, int1, propertyIndex2, int2, propertyIndex3, int3)
end

function I:SetHologramProjectorURL(index, url)
end

function I:SetPosterHolderURL(index, url)
end

return I