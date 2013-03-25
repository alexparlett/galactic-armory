//advisor_const.as
//=================
//constants

Color cG(0xff00ff00);
Color cY(0xffffff00);
Color cR(0xffff0000);
Color cW(0xffffffff);
Color cEven(0xff303030);
Color cOdd(0xff282828);
Color cSelected(0xff283c28);
Color transparent(0xdaffffff);
Color opaque(0xffffffff);

//Conversion ratios between resources
const float MTL_TO_ELC = 2.f;
const float MTL_TO_ADV = 1.f;
const float ELC_TO_ADV = 1.f;
const float MTL_TO_AMO = 0.5f;

const string@ strAdvGen = "AdvG", strAdvGenOpt = "AdvGOpt", strElcGen = "ElcG", strElcGenOpt = "ElcGOpt", strMtlGen = "MineM", strMtlGenOpt = "MineMOpt", strAmmoG = "AmmoG";
const string@ strMtl = "Metals", strElc = "Electronics", strAdv = "AdvParts", strLabr = "Labr";
const string@ strTrade = "Trade", strTradeTarget = "TradeTarget";
const string@ strHousing = "Housing", strWorkers = "Workers";
