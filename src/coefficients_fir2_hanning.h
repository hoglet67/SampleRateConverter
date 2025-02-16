#ifndef _COEFFICIENTS_H
#define _COEFFICIENTS_H

#define NTAPS 3840

int hc[NTAPS] = {
    8,
    8,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    8,
    8,
    8,
    8,
    8,
    8,
    7,
    7,
    7,
    7,
    7,
    6,
    6,
    6,
    6,
    5,
    5,
    5,
    5,
    4,
    4,
    4,
    3,
    3,
    3,
    2,
    2,
    2,
    1,
    1,
    0,
    0,
    -0,
    -1,
    -1,
    -2,
    -2,
    -2,
    -3,
    -3,
    -4,
    -4,
    -5,
    -5,
    -6,
    -6,
    -6,
    -7,
    -7,
    -8,
    -8,
    -9,
    -9,
    -10,
    -10,
    -11,
    -11,
    -12,
    -12,
    -13,
    -13,
    -14,
    -14,
    -15,
    -15,
    -16,
    -16,
    -17,
    -17,
    -18,
    -18,
    -19,
    -19,
    -19,
    -20,
    -20,
    -21,
    -21,
    -22,
    -22,
    -23,
    -23,
    -23,
    -24,
    -24,
    -25,
    -25,
    -25,
    -26,
    -26,
    -26,
    -27,
    -27,
    -27,
    -28,
    -28,
    -28,
    -28,
    -29,
    -29,
    -29,
    -29,
    -29,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -31,
    -31,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -29,
    -29,
    -29,
    -29,
    -28,
    -28,
    -28,
    -27,
    -27,
    -27,
    -26,
    -26,
    -25,
    -25,
    -25,
    -24,
    -24,
    -23,
    -22,
    -22,
    -21,
    -21,
    -20,
    -19,
    -19,
    -18,
    -17,
    -17,
    -16,
    -15,
    -14,
    -14,
    -13,
    -12,
    -11,
    -10,
    -9,
    -9,
    -8,
    -7,
    -6,
    -5,
    -4,
    -3,
    -2,
    -1,
    0,
    1,
    2,
    3,
    4,
    5,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    16,
    17,
    18,
    19,
    20,
    21,
    23,
    24,
    25,
    26,
    27,
    28,
    30,
    31,
    32,
    33,
    34,
    35,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
    44,
    46,
    47,
    48,
    49,
    50,
    51,
    52,
    53,
    54,
    55,
    56,
    56,
    57,
    58,
    59,
    60,
    61,
    61,
    62,
    63,
    64,
    64,
    65,
    66,
    66,
    67,
    67,
    68,
    68,
    69,
    69,
    69,
    70,
    70,
    70,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    70,
    70,
    70,
    69,
    69,
    69,
    68,
    67,
    67,
    66,
    66,
    65,
    64,
    63,
    63,
    62,
    61,
    60,
    59,
    58,
    57,
    56,
    54,
    53,
    52,
    51,
    49,
    48,
    47,
    45,
    44,
    42,
    41,
    39,
    38,
    36,
    34,
    32,
    31,
    29,
    27,
    25,
    23,
    21,
    20,
    18,
    16,
    13,
    11,
    9,
    7,
    5,
    3,
    1,
    -1,
    -4,
    -6,
    -8,
    -10,
    -13,
    -15,
    -17,
    -20,
    -22,
    -24,
    -27,
    -29,
    -31,
    -34,
    -36,
    -39,
    -41,
    -43,
    -46,
    -48,
    -51,
    -53,
    -55,
    -58,
    -60,
    -62,
    -65,
    -67,
    -69,
    -72,
    -74,
    -76,
    -78,
    -81,
    -83,
    -85,
    -87,
    -89,
    -91,
    -93,
    -95,
    -97,
    -99,
    -101,
    -103,
    -105,
    -107,
    -109,
    -110,
    -112,
    -114,
    -115,
    -117,
    -118,
    -120,
    -121,
    -123,
    -124,
    -125,
    -126,
    -127,
    -128,
    -129,
    -130,
    -131,
    -132,
    -133,
    -134,
    -134,
    -135,
    -136,
    -136,
    -136,
    -137,
    -137,
    -137,
    -137,
    -137,
    -137,
    -137,
    -137,
    -137,
    -137,
    -136,
    -136,
    -135,
    -135,
    -134,
    -133,
    -132,
    -131,
    -130,
    -129,
    -128,
    -127,
    -126,
    -124,
    -123,
    -122,
    -120,
    -118,
    -117,
    -115,
    -113,
    -111,
    -109,
    -107,
    -105,
    -103,
    -100,
    -98,
    -96,
    -93,
    -91,
    -88,
    -85,
    -83,
    -80,
    -77,
    -74,
    -71,
    -68,
    -65,
    -62,
    -59,
    -55,
    -52,
    -49,
    -45,
    -42,
    -38,
    -35,
    -31,
    -28,
    -24,
    -20,
    -17,
    -13,
    -9,
    -5,
    -2,
    2,
    6,
    10,
    14,
    18,
    22,
    26,
    30,
    34,
    38,
    42,
    46,
    50,
    54,
    58,
    62,
    66,
    70,
    74,
    78,
    82,
    86,
    90,
    93,
    97,
    101,
    105,
    109,
    112,
    116,
    120,
    123,
    127,
    130,
    134,
    137,
    141,
    144,
    147,
    151,
    154,
    157,
    160,
    163,
    166,
    169,
    171,
    174,
    177,
    179,
    182,
    184,
    186,
    189,
    191,
    193,
    195,
    197,
    198,
    200,
    202,
    203,
    205,
    206,
    207,
    208,
    209,
    210,
    211,
    212,
    212,
    213,
    213,
    213,
    214,
    214,
    214,
    213,
    213,
    213,
    212,
    212,
    211,
    210,
    209,
    208,
    207,
    206,
    204,
    203,
    201,
    200,
    198,
    196,
    194,
    192,
    190,
    187,
    185,
    182,
    180,
    177,
    174,
    171,
    168,
    165,
    162,
    159,
    155,
    152,
    148,
    144,
    141,
    137,
    133,
    129,
    125,
    121,
    116,
    112,
    108,
    103,
    99,
    94,
    89,
    85,
    80,
    75,
    70,
    65,
    60,
    55,
    50,
    45,
    40,
    35,
    30,
    25,
    19,
    14,
    9,
    3,
    -2,
    -7,
    -13,
    -18,
    -23,
    -29,
    -34,
    -39,
    -45,
    -50,
    -55,
    -61,
    -66,
    -71,
    -76,
    -82,
    -87,
    -92,
    -97,
    -102,
    -107,
    -112,
    -117,
    -122,
    -127,
    -131,
    -136,
    -141,
    -145,
    -150,
    -154,
    -159,
    -163,
    -167,
    -171,
    -175,
    -179,
    -183,
    -187,
    -191,
    -194,
    -198,
    -201,
    -205,
    -208,
    -211,
    -214,
    -217,
    -219,
    -222,
    -225,
    -227,
    -229,
    -232,
    -234,
    -236,
    -238,
    -239,
    -241,
    -242,
    -244,
    -245,
    -246,
    -247,
    -248,
    -249,
    -249,
    -250,
    -250,
    -250,
    -251,
    -250,
    -250,
    -250,
    -250,
    -249,
    -248,
    -248,
    -247,
    -246,
    -244,
    -243,
    -242,
    -240,
    -238,
    -237,
    -235,
    -233,
    -230,
    -228,
    -226,
    -223,
    -221,
    -218,
    -215,
    -212,
    -209,
    -206,
    -203,
    -199,
    -196,
    -192,
    -189,
    -185,
    -181,
    -177,
    -173,
    -169,
    -165,
    -161,
    -157,
    -152,
    -148,
    -143,
    -139,
    -134,
    -129,
    -125,
    -120,
    -115,
    -110,
    -105,
    -100,
    -95,
    -90,
    -85,
    -80,
    -75,
    -70,
    -65,
    -60,
    -55,
    -50,
    -44,
    -39,
    -34,
    -29,
    -24,
    -19,
    -14,
    -9,
    -3,
    2,
    7,
    11,
    16,
    21,
    26,
    31,
    36,
    40,
    45,
    50,
    54,
    59,
    63,
    67,
    72,
    76,
    80,
    84,
    88,
    92,
    96,
    100,
    103,
    107,
    110,
    114,
    117,
    120,
    123,
    126,
    129,
    132,
    134,
    137,
    139,
    142,
    144,
    146,
    148,
    150,
    151,
    153,
    155,
    156,
    157,
    159,
    160,
    161,
    161,
    162,
    163,
    163,
    164,
    164,
    164,
    164,
    164,
    164,
    163,
    163,
    162,
    162,
    161,
    160,
    159,
    158,
    157,
    156,
    155,
    153,
    152,
    150,
    148,
    146,
    145,
    143,
    141,
    139,
    136,
    134,
    132,
    129,
    127,
    124,
    122,
    119,
    117,
    114,
    111,
    108,
    105,
    103,
    100,
    97,
    94,
    91,
    88,
    85,
    82,
    79,
    76,
    73,
    70,
    67,
    64,
    61,
    58,
    55,
    52,
    49,
    46,
    43,
    40,
    38,
    35,
    32,
    30,
    27,
    25,
    22,
    20,
    18,
    16,
    13,
    11,
    9,
    8,
    6,
    4,
    2,
    1,
    -0,
    -2,
    -3,
    -4,
    -5,
    -6,
    -7,
    -7,
    -8,
    -8,
    -9,
    -9,
    -9,
    -9,
    -9,
    -8,
    -8,
    -7,
    -7,
    -6,
    -5,
    -4,
    -3,
    -1,
    0,
    2,
    3,
    5,
    7,
    9,
    12,
    14,
    16,
    19,
    22,
    25,
    28,
    31,
    34,
    37,
    41,
    44,
    48,
    51,
    55,
    59,
    63,
    67,
    72,
    76,
    80,
    85,
    89,
    94,
    99,
    103,
    108,
    113,
    118,
    123,
    128,
    133,
    138,
    143,
    148,
    153,
    159,
    164,
    169,
    174,
    179,
    184,
    189,
    195,
    200,
    205,
    210,
    215,
    219,
    224,
    229,
    234,
    238,
    243,
    247,
    251,
    256,
    260,
    264,
    267,
    271,
    275,
    278,
    281,
    285,
    288,
    290,
    293,
    296,
    298,
    300,
    302,
    303,
    305,
    306,
    307,
    308,
    309,
    309,
    309,
    309,
    309,
    308,
    307,
    306,
    305,
    303,
    301,
    299,
    296,
    294,
    291,
    287,
    284,
    280,
    275,
    271,
    266,
    261,
    255,
    249,
    243,
    237,
    230,
    223,
    216,
    208,
    200,
    192,
    183,
    174,
    165,
    155,
    145,
    135,
    125,
    114,
    103,
    91,
    79,
    67,
    55,
    42,
    30,
    16,
    3,
    -11,
    -25,
    -39,
    -54,
    -68,
    -84,
    -99,
    -114,
    -130,
    -146,
    -162,
    -179,
    -195,
    -212,
    -229,
    -246,
    -264,
    -281,
    -299,
    -316,
    -334,
    -352,
    -371,
    -389,
    -407,
    -426,
    -444,
    -463,
    -481,
    -500,
    -519,
    -537,
    -556,
    -575,
    -593,
    -612,
    -630,
    -649,
    -667,
    -686,
    -704,
    -722,
    -740,
    -758,
    -776,
    -793,
    -811,
    -828,
    -845,
    -862,
    -878,
    -895,
    -911,
    -927,
    -942,
    -957,
    -972,
    -987,
    -1001,
    -1015,
    -1028,
    -1041,
    -1054,
    -1066,
    -1078,
    -1090,
    -1101,
    -1111,
    -1121,
    -1131,
    -1140,
    -1148,
    -1156,
    -1164,
    -1171,
    -1177,
    -1183,
    -1188,
    -1193,
    -1197,
    -1200,
    -1203,
    -1205,
    -1206,
    -1207,
    -1207,
    -1207,
    -1205,
    -1203,
    -1201,
    -1197,
    -1193,
    -1188,
    -1183,
    -1177,
    -1170,
    -1162,
    -1153,
    -1144,
    -1134,
    -1123,
    -1111,
    -1099,
    -1086,
    -1072,
    -1057,
    -1041,
    -1025,
    -1008,
    -990,
    -971,
    -952,
    -931,
    -910,
    -888,
    -865,
    -842,
    -818,
    -793,
    -767,
    -740,
    -713,
    -685,
    -656,
    -626,
    -596,
    -565,
    -533,
    -501,
    -468,
    -434,
    -399,
    -364,
    -328,
    -292,
    -255,
    -217,
    -179,
    -140,
    -100,
    -60,
    -20,
    21,
    63,
    105,
    147,
    190,
    234,
    278,
    322,
    367,
    412,
    457,
    503,
    549,
    595,
    641,
    688,
    735,
    782,
    829,
    876,
    924,
    971,
    1019,
    1067,
    1114,
    1162,
    1209,
    1257,
    1304,
    1351,
    1398,
    1445,
    1492,
    1538,
    1584,
    1630,
    1676,
    1721,
    1766,
    1810,
    1854,
    1897,
    1940,
    1982,
    2024,
    2065,
    2106,
    2146,
    2185,
    2224,
    2262,
    2299,
    2335,
    2370,
    2405,
    2438,
    2471,
    2503,
    2534,
    2564,
    2593,
    2620,
    2647,
    2673,
    2697,
    2721,
    2743,
    2764,
    2784,
    2802,
    2819,
    2835,
    2850,
    2863,
    2875,
    2886,
    2895,
    2903,
    2909,
    2914,
    2917,
    2919,
    2919,
    2918,
    2915,
    2911,
    2905,
    2898,
    2889,
    2878,
    2866,
    2852,
    2836,
    2819,
    2800,
    2780,
    2757,
    2733,
    2708,
    2681,
    2652,
    2621,
    2589,
    2555,
    2519,
    2481,
    2442,
    2402,
    2359,
    2315,
    2269,
    2222,
    2173,
    2122,
    2069,
    2015,
    1960,
    1903,
    1844,
    1783,
    1722,
    1658,
    1593,
    1527,
    1459,
    1389,
    1319,
    1246,
    1173,
    1098,
    1022,
    944,
    865,
    785,
    704,
    621,
    538,
    453,
    367,
    280,
    192,
    103,
    13,
    -77,
    -169,
    -261,
    -355,
    -449,
    -543,
    -639,
    -735,
    -831,
    -928,
    -1026,
    -1124,
    -1222,
    -1321,
    -1420,
    -1519,
    -1619,
    -1718,
    -1818,
    -1918,
    -2017,
    -2117,
    -2217,
    -2316,
    -2415,
    -2514,
    -2612,
    -2710,
    -2808,
    -2905,
    -3002,
    -3098,
    -3193,
    -3288,
    -3382,
    -3475,
    -3567,
    -3658,
    -3748,
    -3837,
    -3925,
    -4012,
    -4098,
    -4182,
    -4265,
    -4347,
    -4427,
    -4505,
    -4582,
    -4658,
    -4732,
    -4804,
    -4874,
    -4942,
    -5009,
    -5073,
    -5136,
    -5197,
    -5255,
    -5311,
    -5366,
    -5417,
    -5467,
    -5514,
    -5559,
    -5602,
    -5642,
    -5679,
    -5714,
    -5747,
    -5776,
    -5803,
    -5828,
    -5849,
    -5868,
    -5884,
    -5897,
    -5907,
    -5915,
    -5919,
    -5920,
    -5919,
    -5914,
    -5906,
    -5895,
    -5881,
    -5864,
    -5844,
    -5821,
    -5794,
    -5764,
    -5731,
    -5695,
    -5656,
    -5613,
    -5567,
    -5518,
    -5465,
    -5409,
    -5350,
    -5288,
    -5222,
    -5153,
    -5081,
    -5006,
    -4927,
    -4845,
    -4760,
    -4672,
    -4581,
    -4486,
    -4388,
    -4287,
    -4184,
    -4076,
    -3966,
    -3853,
    -3737,
    -3618,
    -3496,
    -3371,
    -3243,
    -3113,
    -2979,
    -2843,
    -2705,
    -2563,
    -2419,
    -2273,
    -2124,
    -1972,
    -1818,
    -1662,
    -1504,
    -1343,
    -1181,
    -1016,
    -849,
    -680,
    -510,
    -337,
    -163,
    13,
    190,
    369,
    549,
    731,
    914,
    1098,
    1283,
    1470,
    1657,
    1845,
    2034,
    2223,
    2414,
    2604,
    2795,
    2986,
    3178,
    3370,
    3561,
    3753,
    3944,
    4136,
    4326,
    4517,
    4706,
    4895,
    5084,
    5271,
    5458,
    5643,
    5827,
    6010,
    6192,
    6372,
    6550,
    6727,
    6902,
    7075,
    7246,
    7415,
    7582,
    7746,
    7908,
    8067,
    8224,
    8378,
    8529,
    8678,
    8823,
    8965,
    9104,
    9239,
    9371,
    9500,
    9624,
    9746,
    9863,
    9976,
    10086,
    10191,
    10292,
    10389,
    10481,
    10569,
    10653,
    10732,
    10806,
    10875,
    10940,
    10999,
    11054,
    11103,
    11148,
    11187,
    11221,
    11249,
    11272,
    11290,
    11302,
    11309,
    11310,
    11305,
    11294,
    11278,
    11256,
    11227,
    11193,
    11154,
    11108,
    11056,
    10998,
    10933,
    10863,
    10787,
    10705,
    10616,
    10521,
    10420,
    10313,
    10200,
    10080,
    9954,
    9822,
    9684,
    9540,
    9390,
    9233,
    9071,
    8902,
    8727,
    8546,
    8359,
    8167,
    7968,
    7763,
    7553,
    7336,
    7114,
    6887,
    6654,
    6415,
    6170,
    5921,
    5666,
    5405,
    5140,
    4869,
    4593,
    4312,
    4027,
    3736,
    3441,
    3142,
    2838,
    2529,
    2217,
    1900,
    1579,
    1254,
    926,
    594,
    258,
    -81,
    -423,
    -769,
    -1117,
    -1469,
    -1823,
    -2179,
    -2538,
    -2900,
    -3263,
    -3629,
    -3996,
    -4365,
    -4735,
    -5107,
    -5479,
    -5853,
    -6228,
    -6603,
    -6979,
    -7355,
    -7731,
    -8107,
    -8482,
    -8857,
    -9232,
    -9606,
    -9979,
    -10350,
    -10720,
    -11089,
    -11456,
    -11821,
    -12183,
    -12544,
    -12902,
    -13257,
    -13609,
    -13957,
    -14303,
    -14645,
    -14983,
    -15318,
    -15648,
    -15973,
    -16295,
    -16611,
    -16922,
    -17229,
    -17530,
    -17825,
    -18115,
    -18398,
    -18676,
    -18947,
    -19211,
    -19469,
    -19720,
    -19964,
    -20200,
    -20429,
    -20650,
    -20863,
    -21068,
    -21265,
    -21453,
    -21633,
    -21804,
    -21965,
    -22118,
    -22261,
    -22395,
    -22519,
    -22633,
    -22737,
    -22831,
    -22914,
    -22987,
    -23050,
    -23101,
    -23141,
    -23171,
    -23189,
    -23195,
    -23190,
    -23174,
    -23145,
    -23105,
    -23052,
    -22988,
    -22911,
    -22821,
    -22720,
    -22605,
    -22478,
    -22338,
    -22185,
    -22018,
    -21839,
    -21647,
    -21441,
    -21222,
    -20990,
    -20744,
    -20485,
    -20212,
    -19925,
    -19625,
    -19311,
    -18983,
    -18641,
    -18286,
    -17917,
    -17534,
    -17137,
    -16726,
    -16301,
    -15862,
    -15410,
    -14943,
    -14463,
    -13969,
    -13461,
    -12939,
    -12404,
    -11855,
    -11292,
    -10716,
    -10126,
    -9522,
    -8905,
    -8275,
    -7632,
    -6975,
    -6305,
    -5623,
    -4927,
    -4218,
    -3497,
    -2763,
    -2017,
    -1259,
    -488,
    295,
    1090,
    1897,
    2715,
    3545,
    4386,
    5239,
    6102,
    6977,
    7862,
    8757,
    9663,
    10579,
    11505,
    12441,
    13386,
    14341,
    15305,
    16277,
    17259,
    18249,
    19247,
    20253,
    21267,
    22289,
    23318,
    24354,
    25397,
    26446,
    27502,
    28564,
    29631,
    30705,
    31783,
    32867,
    33955,
    35048,
    36144,
    37245,
    38350,
    39458,
    40568,
    41682,
    42798,
    43916,
    45036,
    46158,
    47281,
    48405,
    49530,
    50655,
    51780,
    52905,
    54030,
    55153,
    56276,
    57397,
    58516,
    59633,
    60748,
    61860,
    62969,
    64075,
    65177,
    66275,
    67369,
    68458,
    69543,
    70622,
    71696,
    72764,
    73826,
    74882,
    75930,
    76972,
    78007,
    79034,
    80053,
    81063,
    82066,
    83059,
    84043,
    85018,
    85984,
    86939,
    87884,
    88819,
    89743,
    90655,
    91557,
    92447,
    93325,
    94190,
    95044,
    95885,
    96713,
    97527,
    98329,
    99116,
    99890,
    100650,
    101395,
    102126,
    102842,
    103544,
    104229,
    104900,
    105555,
    106194,
    106817,
    107424,
    108014,
    108588,
    109145,
    109685,
    110208,
    110714,
    111203,
    111674,
    112127,
    112563,
    112980,
    113379,
    113761,
    114124,
    114468,
    114794,
    115101,
    115390,
    115659,
    115910,
    116142,
    116354,
    116548,
    116722,
    116878,
    117013,
    117130,
    117227,
    117305,
    117363,
    117402,
    117422,
    117422,
    117402,
    117363,
    117305,
    117227,
    117130,
    117013,
    116878,
    116722,
    116548,
    116354,
    116142,
    115910,
    115659,
    115390,
    115101,
    114794,
    114468,
    114124,
    113761,
    113379,
    112980,
    112563,
    112127,
    111674,
    111203,
    110714,
    110208,
    109685,
    109145,
    108588,
    108014,
    107424,
    106817,
    106194,
    105555,
    104900,
    104229,
    103544,
    102842,
    102126,
    101395,
    100650,
    99890,
    99116,
    98329,
    97527,
    96713,
    95885,
    95044,
    94190,
    93325,
    92447,
    91557,
    90655,
    89743,
    88819,
    87884,
    86939,
    85984,
    85018,
    84043,
    83059,
    82066,
    81063,
    80053,
    79034,
    78007,
    76972,
    75930,
    74882,
    73826,
    72764,
    71696,
    70622,
    69543,
    68458,
    67369,
    66275,
    65177,
    64075,
    62969,
    61860,
    60748,
    59633,
    58516,
    57397,
    56276,
    55153,
    54030,
    52905,
    51780,
    50655,
    49530,
    48405,
    47281,
    46158,
    45036,
    43916,
    42798,
    41682,
    40568,
    39458,
    38350,
    37245,
    36144,
    35048,
    33955,
    32867,
    31783,
    30705,
    29631,
    28564,
    27502,
    26446,
    25397,
    24354,
    23318,
    22289,
    21267,
    20253,
    19247,
    18249,
    17259,
    16277,
    15305,
    14341,
    13386,
    12441,
    11505,
    10579,
    9663,
    8757,
    7862,
    6977,
    6102,
    5239,
    4386,
    3545,
    2715,
    1897,
    1090,
    295,
    -488,
    -1259,
    -2017,
    -2763,
    -3497,
    -4218,
    -4927,
    -5623,
    -6305,
    -6975,
    -7632,
    -8275,
    -8905,
    -9522,
    -10126,
    -10716,
    -11292,
    -11855,
    -12404,
    -12939,
    -13461,
    -13969,
    -14463,
    -14943,
    -15410,
    -15862,
    -16301,
    -16726,
    -17137,
    -17534,
    -17917,
    -18286,
    -18641,
    -18983,
    -19311,
    -19625,
    -19925,
    -20212,
    -20485,
    -20744,
    -20990,
    -21222,
    -21441,
    -21647,
    -21839,
    -22018,
    -22185,
    -22338,
    -22478,
    -22605,
    -22720,
    -22821,
    -22911,
    -22988,
    -23052,
    -23105,
    -23145,
    -23174,
    -23190,
    -23195,
    -23189,
    -23171,
    -23141,
    -23101,
    -23050,
    -22987,
    -22914,
    -22831,
    -22737,
    -22633,
    -22519,
    -22395,
    -22261,
    -22118,
    -21965,
    -21804,
    -21633,
    -21453,
    -21265,
    -21068,
    -20863,
    -20650,
    -20429,
    -20200,
    -19964,
    -19720,
    -19469,
    -19211,
    -18947,
    -18676,
    -18398,
    -18115,
    -17825,
    -17530,
    -17229,
    -16922,
    -16611,
    -16295,
    -15973,
    -15648,
    -15318,
    -14983,
    -14645,
    -14303,
    -13957,
    -13609,
    -13257,
    -12902,
    -12544,
    -12183,
    -11821,
    -11456,
    -11089,
    -10720,
    -10350,
    -9979,
    -9606,
    -9232,
    -8857,
    -8482,
    -8107,
    -7731,
    -7355,
    -6979,
    -6603,
    -6228,
    -5853,
    -5479,
    -5107,
    -4735,
    -4365,
    -3996,
    -3629,
    -3263,
    -2900,
    -2538,
    -2179,
    -1823,
    -1469,
    -1117,
    -769,
    -423,
    -81,
    258,
    594,
    926,
    1254,
    1579,
    1900,
    2217,
    2529,
    2838,
    3142,
    3441,
    3736,
    4027,
    4312,
    4593,
    4869,
    5140,
    5405,
    5666,
    5921,
    6170,
    6415,
    6654,
    6887,
    7114,
    7336,
    7553,
    7763,
    7968,
    8167,
    8359,
    8546,
    8727,
    8902,
    9071,
    9233,
    9390,
    9540,
    9684,
    9822,
    9954,
    10080,
    10200,
    10313,
    10420,
    10521,
    10616,
    10705,
    10787,
    10863,
    10933,
    10998,
    11056,
    11108,
    11154,
    11193,
    11227,
    11256,
    11278,
    11294,
    11305,
    11310,
    11309,
    11302,
    11290,
    11272,
    11249,
    11221,
    11187,
    11148,
    11103,
    11054,
    10999,
    10940,
    10875,
    10806,
    10732,
    10653,
    10569,
    10481,
    10389,
    10292,
    10191,
    10086,
    9976,
    9863,
    9746,
    9624,
    9500,
    9371,
    9239,
    9104,
    8965,
    8823,
    8678,
    8529,
    8378,
    8224,
    8067,
    7908,
    7746,
    7582,
    7415,
    7246,
    7075,
    6902,
    6727,
    6550,
    6372,
    6192,
    6010,
    5827,
    5643,
    5458,
    5271,
    5084,
    4895,
    4706,
    4517,
    4326,
    4136,
    3944,
    3753,
    3561,
    3370,
    3178,
    2986,
    2795,
    2604,
    2414,
    2223,
    2034,
    1845,
    1657,
    1470,
    1283,
    1098,
    914,
    731,
    549,
    369,
    190,
    13,
    -163,
    -337,
    -510,
    -680,
    -849,
    -1016,
    -1181,
    -1343,
    -1504,
    -1662,
    -1818,
    -1972,
    -2124,
    -2273,
    -2419,
    -2563,
    -2705,
    -2843,
    -2979,
    -3113,
    -3243,
    -3371,
    -3496,
    -3618,
    -3737,
    -3853,
    -3966,
    -4076,
    -4184,
    -4287,
    -4388,
    -4486,
    -4581,
    -4672,
    -4760,
    -4845,
    -4927,
    -5006,
    -5081,
    -5153,
    -5222,
    -5288,
    -5350,
    -5409,
    -5465,
    -5518,
    -5567,
    -5613,
    -5656,
    -5695,
    -5731,
    -5764,
    -5794,
    -5821,
    -5844,
    -5864,
    -5881,
    -5895,
    -5906,
    -5914,
    -5919,
    -5920,
    -5919,
    -5915,
    -5907,
    -5897,
    -5884,
    -5868,
    -5849,
    -5828,
    -5803,
    -5776,
    -5747,
    -5714,
    -5679,
    -5642,
    -5602,
    -5559,
    -5514,
    -5467,
    -5417,
    -5366,
    -5311,
    -5255,
    -5197,
    -5136,
    -5073,
    -5009,
    -4942,
    -4874,
    -4804,
    -4732,
    -4658,
    -4582,
    -4505,
    -4427,
    -4347,
    -4265,
    -4182,
    -4098,
    -4012,
    -3925,
    -3837,
    -3748,
    -3658,
    -3567,
    -3475,
    -3382,
    -3288,
    -3193,
    -3098,
    -3002,
    -2905,
    -2808,
    -2710,
    -2612,
    -2514,
    -2415,
    -2316,
    -2217,
    -2117,
    -2017,
    -1918,
    -1818,
    -1718,
    -1619,
    -1519,
    -1420,
    -1321,
    -1222,
    -1124,
    -1026,
    -928,
    -831,
    -735,
    -639,
    -543,
    -449,
    -355,
    -261,
    -169,
    -77,
    13,
    103,
    192,
    280,
    367,
    453,
    538,
    621,
    704,
    785,
    865,
    944,
    1022,
    1098,
    1173,
    1246,
    1319,
    1389,
    1459,
    1527,
    1593,
    1658,
    1722,
    1783,
    1844,
    1903,
    1960,
    2015,
    2069,
    2122,
    2173,
    2222,
    2269,
    2315,
    2359,
    2402,
    2442,
    2481,
    2519,
    2555,
    2589,
    2621,
    2652,
    2681,
    2708,
    2733,
    2757,
    2780,
    2800,
    2819,
    2836,
    2852,
    2866,
    2878,
    2889,
    2898,
    2905,
    2911,
    2915,
    2918,
    2919,
    2919,
    2917,
    2914,
    2909,
    2903,
    2895,
    2886,
    2875,
    2863,
    2850,
    2835,
    2819,
    2802,
    2784,
    2764,
    2743,
    2721,
    2697,
    2673,
    2647,
    2620,
    2593,
    2564,
    2534,
    2503,
    2471,
    2438,
    2405,
    2370,
    2335,
    2299,
    2262,
    2224,
    2185,
    2146,
    2106,
    2065,
    2024,
    1982,
    1940,
    1897,
    1854,
    1810,
    1766,
    1721,
    1676,
    1630,
    1584,
    1538,
    1492,
    1445,
    1398,
    1351,
    1304,
    1257,
    1209,
    1162,
    1114,
    1067,
    1019,
    971,
    924,
    876,
    829,
    782,
    735,
    688,
    641,
    595,
    549,
    503,
    457,
    412,
    367,
    322,
    278,
    234,
    190,
    147,
    105,
    63,
    21,
    -20,
    -60,
    -100,
    -140,
    -179,
    -217,
    -255,
    -292,
    -328,
    -364,
    -399,
    -434,
    -468,
    -501,
    -533,
    -565,
    -596,
    -626,
    -656,
    -685,
    -713,
    -740,
    -767,
    -793,
    -818,
    -842,
    -865,
    -888,
    -910,
    -931,
    -952,
    -971,
    -990,
    -1008,
    -1025,
    -1041,
    -1057,
    -1072,
    -1086,
    -1099,
    -1111,
    -1123,
    -1134,
    -1144,
    -1153,
    -1162,
    -1170,
    -1177,
    -1183,
    -1188,
    -1193,
    -1197,
    -1201,
    -1203,
    -1205,
    -1207,
    -1207,
    -1207,
    -1206,
    -1205,
    -1203,
    -1200,
    -1197,
    -1193,
    -1188,
    -1183,
    -1177,
    -1171,
    -1164,
    -1156,
    -1148,
    -1140,
    -1131,
    -1121,
    -1111,
    -1101,
    -1090,
    -1078,
    -1066,
    -1054,
    -1041,
    -1028,
    -1015,
    -1001,
    -987,
    -972,
    -957,
    -942,
    -927,
    -911,
    -895,
    -878,
    -862,
    -845,
    -828,
    -811,
    -793,
    -776,
    -758,
    -740,
    -722,
    -704,
    -686,
    -667,
    -649,
    -630,
    -612,
    -593,
    -575,
    -556,
    -537,
    -519,
    -500,
    -481,
    -463,
    -444,
    -426,
    -407,
    -389,
    -371,
    -352,
    -334,
    -316,
    -299,
    -281,
    -264,
    -246,
    -229,
    -212,
    -195,
    -179,
    -162,
    -146,
    -130,
    -114,
    -99,
    -84,
    -68,
    -54,
    -39,
    -25,
    -11,
    3,
    16,
    30,
    42,
    55,
    67,
    79,
    91,
    103,
    114,
    125,
    135,
    145,
    155,
    165,
    174,
    183,
    192,
    200,
    208,
    216,
    223,
    230,
    237,
    243,
    249,
    255,
    261,
    266,
    271,
    275,
    280,
    284,
    287,
    291,
    294,
    296,
    299,
    301,
    303,
    305,
    306,
    307,
    308,
    309,
    309,
    309,
    309,
    309,
    308,
    307,
    306,
    305,
    303,
    302,
    300,
    298,
    296,
    293,
    290,
    288,
    285,
    281,
    278,
    275,
    271,
    267,
    264,
    260,
    256,
    251,
    247,
    243,
    238,
    234,
    229,
    224,
    219,
    215,
    210,
    205,
    200,
    195,
    189,
    184,
    179,
    174,
    169,
    164,
    159,
    153,
    148,
    143,
    138,
    133,
    128,
    123,
    118,
    113,
    108,
    103,
    99,
    94,
    89,
    85,
    80,
    76,
    72,
    67,
    63,
    59,
    55,
    51,
    48,
    44,
    41,
    37,
    34,
    31,
    28,
    25,
    22,
    19,
    16,
    14,
    12,
    9,
    7,
    5,
    3,
    2,
    0,
    -1,
    -3,
    -4,
    -5,
    -6,
    -7,
    -7,
    -8,
    -8,
    -9,
    -9,
    -9,
    -9,
    -9,
    -8,
    -8,
    -7,
    -7,
    -6,
    -5,
    -4,
    -3,
    -2,
    -0,
    1,
    2,
    4,
    6,
    8,
    9,
    11,
    13,
    16,
    18,
    20,
    22,
    25,
    27,
    30,
    32,
    35,
    38,
    40,
    43,
    46,
    49,
    52,
    55,
    58,
    61,
    64,
    67,
    70,
    73,
    76,
    79,
    82,
    85,
    88,
    91,
    94,
    97,
    100,
    103,
    105,
    108,
    111,
    114,
    117,
    119,
    122,
    124,
    127,
    129,
    132,
    134,
    136,
    139,
    141,
    143,
    145,
    146,
    148,
    150,
    152,
    153,
    155,
    156,
    157,
    158,
    159,
    160,
    161,
    162,
    162,
    163,
    163,
    164,
    164,
    164,
    164,
    164,
    164,
    163,
    163,
    162,
    161,
    161,
    160,
    159,
    157,
    156,
    155,
    153,
    151,
    150,
    148,
    146,
    144,
    142,
    139,
    137,
    134,
    132,
    129,
    126,
    123,
    120,
    117,
    114,
    110,
    107,
    103,
    100,
    96,
    92,
    88,
    84,
    80,
    76,
    72,
    67,
    63,
    59,
    54,
    50,
    45,
    40,
    36,
    31,
    26,
    21,
    16,
    11,
    7,
    2,
    -3,
    -9,
    -14,
    -19,
    -24,
    -29,
    -34,
    -39,
    -44,
    -50,
    -55,
    -60,
    -65,
    -70,
    -75,
    -80,
    -85,
    -90,
    -95,
    -100,
    -105,
    -110,
    -115,
    -120,
    -125,
    -129,
    -134,
    -139,
    -143,
    -148,
    -152,
    -157,
    -161,
    -165,
    -169,
    -173,
    -177,
    -181,
    -185,
    -189,
    -192,
    -196,
    -199,
    -203,
    -206,
    -209,
    -212,
    -215,
    -218,
    -221,
    -223,
    -226,
    -228,
    -230,
    -233,
    -235,
    -237,
    -238,
    -240,
    -242,
    -243,
    -244,
    -246,
    -247,
    -248,
    -248,
    -249,
    -250,
    -250,
    -250,
    -250,
    -251,
    -250,
    -250,
    -250,
    -249,
    -249,
    -248,
    -247,
    -246,
    -245,
    -244,
    -242,
    -241,
    -239,
    -238,
    -236,
    -234,
    -232,
    -229,
    -227,
    -225,
    -222,
    -219,
    -217,
    -214,
    -211,
    -208,
    -205,
    -201,
    -198,
    -194,
    -191,
    -187,
    -183,
    -179,
    -175,
    -171,
    -167,
    -163,
    -159,
    -154,
    -150,
    -145,
    -141,
    -136,
    -131,
    -127,
    -122,
    -117,
    -112,
    -107,
    -102,
    -97,
    -92,
    -87,
    -82,
    -76,
    -71,
    -66,
    -61,
    -55,
    -50,
    -45,
    -39,
    -34,
    -29,
    -23,
    -18,
    -13,
    -7,
    -2,
    3,
    9,
    14,
    19,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
    60,
    65,
    70,
    75,
    80,
    85,
    89,
    94,
    99,
    103,
    108,
    112,
    116,
    121,
    125,
    129,
    133,
    137,
    141,
    144,
    148,
    152,
    155,
    159,
    162,
    165,
    168,
    171,
    174,
    177,
    180,
    182,
    185,
    187,
    190,
    192,
    194,
    196,
    198,
    200,
    201,
    203,
    204,
    206,
    207,
    208,
    209,
    210,
    211,
    212,
    212,
    213,
    213,
    213,
    214,
    214,
    214,
    213,
    213,
    213,
    212,
    212,
    211,
    210,
    209,
    208,
    207,
    206,
    205,
    203,
    202,
    200,
    198,
    197,
    195,
    193,
    191,
    189,
    186,
    184,
    182,
    179,
    177,
    174,
    171,
    169,
    166,
    163,
    160,
    157,
    154,
    151,
    147,
    144,
    141,
    137,
    134,
    130,
    127,
    123,
    120,
    116,
    112,
    109,
    105,
    101,
    97,
    93,
    90,
    86,
    82,
    78,
    74,
    70,
    66,
    62,
    58,
    54,
    50,
    46,
    42,
    38,
    34,
    30,
    26,
    22,
    18,
    14,
    10,
    6,
    2,
    -2,
    -5,
    -9,
    -13,
    -17,
    -20,
    -24,
    -28,
    -31,
    -35,
    -38,
    -42,
    -45,
    -49,
    -52,
    -55,
    -59,
    -62,
    -65,
    -68,
    -71,
    -74,
    -77,
    -80,
    -83,
    -85,
    -88,
    -91,
    -93,
    -96,
    -98,
    -100,
    -103,
    -105,
    -107,
    -109,
    -111,
    -113,
    -115,
    -117,
    -118,
    -120,
    -122,
    -123,
    -124,
    -126,
    -127,
    -128,
    -129,
    -130,
    -131,
    -132,
    -133,
    -134,
    -135,
    -135,
    -136,
    -136,
    -137,
    -137,
    -137,
    -137,
    -137,
    -137,
    -137,
    -137,
    -137,
    -137,
    -136,
    -136,
    -136,
    -135,
    -134,
    -134,
    -133,
    -132,
    -131,
    -130,
    -129,
    -128,
    -127,
    -126,
    -125,
    -124,
    -123,
    -121,
    -120,
    -118,
    -117,
    -115,
    -114,
    -112,
    -110,
    -109,
    -107,
    -105,
    -103,
    -101,
    -99,
    -97,
    -95,
    -93,
    -91,
    -89,
    -87,
    -85,
    -83,
    -81,
    -78,
    -76,
    -74,
    -72,
    -69,
    -67,
    -65,
    -62,
    -60,
    -58,
    -55,
    -53,
    -51,
    -48,
    -46,
    -43,
    -41,
    -39,
    -36,
    -34,
    -31,
    -29,
    -27,
    -24,
    -22,
    -20,
    -17,
    -15,
    -13,
    -10,
    -8,
    -6,
    -4,
    -1,
    1,
    3,
    5,
    7,
    9,
    11,
    13,
    16,
    18,
    20,
    21,
    23,
    25,
    27,
    29,
    31,
    32,
    34,
    36,
    38,
    39,
    41,
    42,
    44,
    45,
    47,
    48,
    49,
    51,
    52,
    53,
    54,
    56,
    57,
    58,
    59,
    60,
    61,
    62,
    63,
    63,
    64,
    65,
    66,
    66,
    67,
    67,
    68,
    69,
    69,
    69,
    70,
    70,
    70,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    71,
    70,
    70,
    70,
    69,
    69,
    69,
    68,
    68,
    67,
    67,
    66,
    66,
    65,
    64,
    64,
    63,
    62,
    61,
    61,
    60,
    59,
    58,
    57,
    56,
    56,
    55,
    54,
    53,
    52,
    51,
    50,
    49,
    48,
    47,
    46,
    44,
    43,
    42,
    41,
    40,
    39,
    38,
    37,
    35,
    34,
    33,
    32,
    31,
    30,
    28,
    27,
    26,
    25,
    24,
    23,
    21,
    20,
    19,
    18,
    17,
    16,
    14,
    13,
    12,
    11,
    10,
    9,
    8,
    7,
    5,
    4,
    3,
    2,
    1,
    0,
    -1,
    -2,
    -3,
    -4,
    -5,
    -6,
    -7,
    -8,
    -9,
    -9,
    -10,
    -11,
    -12,
    -13,
    -14,
    -14,
    -15,
    -16,
    -17,
    -17,
    -18,
    -19,
    -19,
    -20,
    -21,
    -21,
    -22,
    -22,
    -23,
    -24,
    -24,
    -25,
    -25,
    -25,
    -26,
    -26,
    -27,
    -27,
    -27,
    -28,
    -28,
    -28,
    -29,
    -29,
    -29,
    -29,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -31,
    -31,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -29,
    -29,
    -29,
    -29,
    -29,
    -28,
    -28,
    -28,
    -28,
    -27,
    -27,
    -27,
    -26,
    -26,
    -26,
    -25,
    -25,
    -25,
    -24,
    -24,
    -23,
    -23,
    -23,
    -22,
    -22,
    -21,
    -21,
    -20,
    -20,
    -19,
    -19,
    -19,
    -18,
    -18,
    -17,
    -17,
    -16,
    -16,
    -15,
    -15,
    -14,
    -14,
    -13,
    -13,
    -12,
    -12,
    -11,
    -11,
    -10,
    -10,
    -9,
    -9,
    -8,
    -8,
    -7,
    -7,
    -6,
    -6,
    -6,
    -5,
    -5,
    -4,
    -4,
    -3,
    -3,
    -2,
    -2,
    -2,
    -1,
    -1,
    -0,
    0,
    0,
    1,
    1,
    2,
    2,
    2,
    3,
    3,
    3,
    4,
    4,
    4,
    5,
    5,
    5,
    5,
    6,
    6,
    6,
    6,
    7,
    7,
    7,
    7,
    7,
    8,
    8,
    8,
    8,
    8,
    8,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    8,
    8
};

#endif
