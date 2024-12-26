//
//  URLList.swift
//  DEH-Make-II
//
//  Created by Ray Chen on 2018/3/19.
//  Copyright © 2018年 Ray Chen. All rights reserved.
//

import Foundation

let UploadPOIUrl:           String = "https://deh.csie.ncku.edu.tw:8080/api/v1/pois/upload"
let POIDetailUrl:           String = "https://deh.csie.ncku.edu.tw/poi_detail/"                       //Share POI used
let DEHHomePageUrl:         String = "https://deh.csie.ncku.edu.tw"
let ExpTainanHomePageUrl:   String = "https://exptainan.liberal.ncku.edu.tw/"
let SDCHomePageUrl:         String = "https://deh.csie.ncku.edu.tw/sdc"
let UserRegistUrl:          String = "https://deh.csie.ncku.edu.tw/regist/"
let UserLoginUrl:           String = "https://deh.csie.ncku.edu.tw:8080/api/v1/users/loginJSON"

let GetCOIListUrl:  String = "https://deh.csie.ncku.edu.tw:8080/api/v1/users/checkCOI"
//MARK:- XOIUrl
let POIClickCountUrl: String = "https://deh.csie.ncku.edu.tw:8080/api/v1/poi_count_click_with_column_name"

//MARK:- GroupUrl
let GroupMemberJoinUrl: String = "https://deh.csie.ncku.edu.tw:8080/api/v1/groups/memberJoin"
let GroupGetNotifiUrl:  String = "https://deh.csie.ncku.edu.tw:8080/api/v1/groups/notification"
let GroupGetGroupUrl:   String = "https://deh.csie.ncku.edu.tw:8080/api/v1/groups/search"
let GroupInviteUrl:     String = "https://deh.csie.ncku.edu.tw:8080/api/v1/groups/message"
let GroupGetMemberUrl:  String = "https://deh.csie.ncku.edu.tw:8080/api/v1/groups/checkMembers"
let GroupCreatUrl:      String = "https://deh.csie.ncku.edu.tw:8080/api/v1/groups/add"
let GroupUpdateUrl:     String = "https://deh.csie.ncku.edu.tw:8080/api/v1/groups/update"
let GroupGetListUrl:    String = "https://deh.csie.ncku.edu.tw:8080/api/v1/groups/groupList"
let GroupGetUserGroupListUrl:    String = "https://deh.csie.ncku.edu.tw:8080/api/v1/groups/searchUserGroups"
let addGroupCountUrl:   String = "https://deh.csie.ncku.edu.tw:8080/api/v1/groups/addGroupLog"
//let addGroupCountUrl:   String = "http:/140.116.82.130:8080//groups/addGroupLog"
//MARK:- GameUrl
let NEW_DEH_API                = "https://deh.csie.ncku.edu.tw:8080/api/v1"
let _DEH_API                   = "https://140.116.82.130:8080/api/v1"
let qrCodeAPI = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data="
let requestURL = "https://deh.csie.ncku.edu.tw/prize_exchange/"
let GamePrizeAttributeUrl      = "https://deh.csie.ncku.edu.tw:8080/api/v1/get_prize_attribute"
let GameGroupListUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/get_group_list"
let GameRoomListUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/get_room_list"
let GameIDUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/get_game_id"
let GameHistoryUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/get_game_history"
let GameDataUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1//get_game_data"

//let getUserAnswerRecord = "https://deh.csie.ncku.edu.tw:8080/api/v1/getUserAnswerRecord"
//let privateGetGroupList = "https://deh.csie.ncku.edu.tw:8080/api/v1/getGroupList"
//let getRoomList = "https://deh.csie.ncku.edu.tw:8080/api/v1/getRoomList"
//let getGameHistory = "https://deh.csie.ncku.edu.tw:8080/api/v1/getGameHistory"
let getChestList = "https://deh.csie.ncku.edu.tw:8080/api/v1/events/chestList"
let getChestMediaUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/getChestMedia"
let insertAnswerUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/insertAnswer"
//let chestMinusUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/chestMinus"
//let getMemberPointUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/getMemberPoint"
let getGameDataUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1//events/gameData"

let privateGetGroupList = "https://deh.csie.ncku.edu.tw:8080/api/v1/events/listEvents"
let getRoomList = "https://deh.csie.ncku.edu.tw:8080/api/v1/events/listSessions"
let chestMinusUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/events/answerChest"

let endGameUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/events/endGame"
let GameStartUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/events/startGame"
let getGameHistory = "https://deh.csie.ncku.edu.tw:8080/api/v1/events/gameHistory"
let getUserAnswerRecord = "https://deh.csie.ncku.edu.tw:8080/api/v1/events/answerRecord"
let getMemberPointUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/events/getMemberPoint"


let uploadMediaAnswerUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/uploadMediaAnswer"
let FieldGetAllListUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/groups/listRegion"

let CreateTempAccountUrl:      String = "https://deh.csie.ncku.edu.tw:8080/api/v1/users/createtempaccount"
let AttachTempAccountUrl:      String = "https://deh.csie.ncku.edu.tw:8080/api/v1/users/attachtempaccount"

//MARK: -PriceUrl
let PrizeGetListUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/get_prize"

//MARK:- XoiUrl
let getPois = "https://deh.csie.ncku.edu.tw:8080/api/v1/users/poisJSON"
//let getXois = [
//    "/API/userPOI":"http://deh.csie.ncku.edu.tw:8080/api/v1/users/poisJSON",
//    "/API/userLOI":"http://deh.csie.ncku.edu.tw:8080/api/v1/users/loisJSON",
//    "/API/userAOI":"http://deh.csie.ncku.edu.tw:8080/api/v1/users/aoisJSON",
//    "/API/userSOI":"http://deh.csie.ncku.edu.tw:8080/api/v1/users/soisJSON",
//]
let getXois = [
    "searchMyPOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/users/poisJSONResponseNormalize",
    "searchMyLOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/users/loisJSONResponseNormalize",
    "searchMyAOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/users/aoisJSONResponseNormalize",
    "searchMySOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/users/soisJSONResponseNormalize",
    
    "searchGroupMyPOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/group/userPOIs",
    "searchGroupMyLOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/group/userLOIs",
    "searchGroupMyAOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/group/userAOIs",
    "searchGroupMySOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/group/userSOIs",
    
    "searchGroupPOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/group/nearbyPOIs",
    "searchGroupLOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/group/nearbyLOIs",
    "searchGroupAOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/group/nearbyAOIs",
    "searchGroupSOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/group/nearbySOIs",
    
    "searchRegionPOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/region/nearbyPOIs",
    "searchRegionLOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/region/nearbyLOIs",
    "searchRegionAOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/region/nearbyAOIs",
    "searchRegionSOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/region/nearbySOIs",
    
]

let getNearbyXois = [
    "searchNearbyPOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/nearby/pois",
    "searchNearbyLOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/nearby/lois",
    "searchNearbyAOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/nearby/aois",
    "searchNearbySOI":"https://deh.csie.ncku.edu.tw:8080/api/v1/nearby/sois",
]
let addPoiCountUrl = "https://deh.csie.ncku.edu.tw:8080/api/v1/add_poi_log"
//let getGroupXois = [
//    "searchGroupPOI":"http://deh.csie.ncku.edu.tw:8080/api/v1/group/userPOIs",
//    "searchGroupLOI":"http://deh.csie.ncku.edu.tw:8080/api/v1/group/userLOIs",
//    "searchGroupAOI":"http://deh.csie.ncku.edu.tw:8080/api/v1/group/userAOIs",
//    "searchGroupSOI":"http://deh.csie.ncku.edu.tw:8080/api/v1/group/userSOIs",
//]
