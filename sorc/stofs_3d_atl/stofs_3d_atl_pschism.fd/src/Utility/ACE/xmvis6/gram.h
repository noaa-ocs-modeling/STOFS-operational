/* A Bison parser, made by GNU Bison 2.7.  */

/* Bison interface for Yacc-like parsers in C
   
      Copyright (C) 1984, 1989-1990, 2000-2012 Free Software Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.
   
   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     VAR = 258,
     X = 259,
     Y = 260,
     CHRSTR = 261,
     FITPARM = 262,
     NUMBER = 263,
     ABS = 264,
     ACOS = 265,
     ASIN = 266,
     ATAN = 267,
     ATAN2 = 268,
     CEIL = 269,
     COS = 270,
     DEG = 271,
     DX = 272,
     DY = 273,
     ERF = 274,
     ERFC = 275,
     EXP = 276,
     FLOOR = 277,
     HYPOT = 278,
     INDEX = 279,
     INT = 280,
     IRAND = 281,
     LGAMMA = 282,
     LN = 283,
     LOG = 284,
     LOGISTIC = 285,
     MAXP = 286,
     MINP = 287,
     MINMAX = 288,
     MOD = 289,
     NORM = 290,
     NORMP = 291,
     PI = 292,
     RAD = 293,
     RAND = 294,
     SETNO = 295,
     SIN = 296,
     SQR = 297,
     SQRT = 298,
     TAN = 299,
     INUM = 300,
     ABORT = 301,
     ABOVE = 302,
     ABSOLUTE = 303,
     ACTIVATE = 304,
     ACTIVE = 305,
     ADCIRC = 306,
     ADCIRC3DFLOW = 307,
     ALL = 308,
     ALT = 309,
     ALTERNATE = 310,
     ALTXAXIS = 311,
     ALTYAXIS = 312,
     AMP = 313,
     ANGLE = 314,
     ANNOTATE = 315,
     APPEND = 316,
     AREA = 317,
     ARROW = 318,
     ASCEND = 319,
     AT = 320,
     ATTACH = 321,
     AUTO = 322,
     AUTOSCALE = 323,
     AUTOTICKS = 324,
     AVERAGE = 325,
     AVG = 326,
     AXES = 327,
     AXIS = 328,
     BACKBUFFER = 329,
     BACKGROUND = 330,
     BAR = 331,
     BATCH = 332,
     BATH = 333,
     BATHYMETRY = 334,
     COURANT = 335,
     BELOW = 336,
     BIN = 337,
     BINARY = 338,
     BOTH = 339,
     BOTTOM = 340,
     BOUNDARY = 341,
     BOX = 342,
     CELLS = 343,
     CENTER = 344,
     CH3D = 345,
     CHAR = 346,
     CHDIR = 347,
     CIRCLE = 348,
     CLEAR = 349,
     CLICK = 350,
     CLOCK = 351,
     CLOSE = 352,
     CM = 353,
     CMAP = 354,
     COLOR = 355,
     COLORMAP = 356,
     COMMENT = 357,
     CONC = 358,
     CONCENTRATION = 359,
     CONCENTRATIONS = 360,
     COPY = 361,
     CROSS = 362,
     CYCLE = 363,
     DAYMONTH = 364,
     DAYOFWEEKL = 365,
     DAYOFWEEKS = 366,
     DAYOFYEAR = 367,
     DAYS = 368,
     DDMMYY = 369,
     DDMONTHSYYHHMMSS = 370,
     DECIMAL = 371,
     DEF = 372,
     DEFAULT = 373,
     DEGREESLAT = 374,
     DEGREESLON = 375,
     DEGREESMMLAT = 376,
     DEGREESMMLON = 377,
     DEGREESMMSSLAT = 378,
     DEGREESMMSSLON = 379,
     DELAYP = 380,
     DELETE = 381,
     DEPTH = 382,
     DEPTHS = 383,
     DESCEND = 384,
     DEVICE = 385,
     DEVXY = 386,
     DFT = 387,
     DT = 388,
     DIAMOND = 389,
     DIFFERENCE = 390,
     DISK = 391,
     DISPLAY = 392,
     DOT = 393,
     DOUBLEBUFFER = 394,
     DOWN = 395,
     DRAW2 = 396,
     DROGUE = 397,
     DROGUES = 398,
     DRY = 399,
     DXDX = 400,
     DXP = 401,
     DYDY = 402,
     DYP = 403,
     ECHO = 404,
     EDIT = 405,
     ELA = 406,
     ELCIRC = 407,
     ELEMENT = 408,
     ELEMENTS = 409,
     ELEV = 410,
     ELEVATION = 411,
     ELEVATIONS = 412,
     ELEVMARKER = 413,
     ELLIPSE = 414,
     ELLIPSES = 415,
     ELLIPSEZ = 416,
     ELSE = 417,
     END = 418,
     ERRORBAR = 419,
     EXIT = 420,
     EXPAND = 421,
     EXPONENTIAL = 422,
     FACTOR = 423,
     FALSEP = 424,
     FAST = 425,
     FEET = 426,
     FFT = 427,
     FILEP = 428,
     FILL = 429,
     FIND = 430,
     FIXEDPOINT = 431,
     FLOW = 432,
     FLUSH = 433,
     FLUX = 434,
     FOCUS = 435,
     FOLLOWS = 436,
     FONTP = 437,
     FOREGROUND = 438,
     FORMAT = 439,
     FORT14 = 440,
     FORT63 = 441,
     FORT64 = 442,
     FORWARD = 443,
     FRAMEP = 444,
     FREQ = 445,
     FRONTBUFFER = 446,
     GENERAL = 447,
     GETP = 448,
     GOTO = 449,
     GRAPH = 450,
     GRAPHNO = 451,
     GRAPHS = 452,
     GRAPHTYPE = 453,
     GRID = 454,
     HARDCOPY = 455,
     HBAR = 456,
     HELP = 457,
     HGAP = 458,
     HIDDEN = 459,
     HISTBOX = 460,
     HISTO = 461,
     HISTORY = 462,
     HMS = 463,
     HORIZONTAL = 464,
     HOURS = 465,
     HPGLL = 466,
     HPGLP = 467,
     IF = 468,
     IGNORE = 469,
     IHL = 470,
     IMAGE = 471,
     IMAGES = 472,
     IN = 473,
     INCLUDE = 474,
     INFO = 475,
     INIT = 476,
     INITGRAPHICS = 477,
     INOUT = 478,
     INTEGRATE = 479,
     INTERP = 480,
     INUNDATION = 481,
     INVDFT = 482,
     INVFFT = 483,
     ISOLINE = 484,
     ISOLINES = 485,
     JUST = 486,
     KILL = 487,
     KM = 488,
     LABEL = 489,
     LAYOUT = 490,
     LEAVE = 491,
     LEAVEGRAPHICS = 492,
     LEFT = 493,
     LEGEND = 494,
     LENGTH = 495,
     LEVEL = 496,
     LEVELS = 497,
     LIMITS = 498,
     LINE = 499,
     LINES = 500,
     LINESTYLE = 501,
     LINETO = 502,
     LINEW = 503,
     LINEWIDTH = 504,
     LINK = 505,
     LOAD = 506,
     LOC = 507,
     LOCATE = 508,
     LOCATOR = 509,
     LOCTYPE = 510,
     LOGX = 511,
     LOGXY = 512,
     LOGY = 513,
     M = 514,
     MAG = 515,
     MAGNITUDE = 516,
     MAJOR = 517,
     MAPSCALE = 518,
     MARKER = 519,
     MARKERS = 520,
     MAXLEVELS = 521,
     METHOD = 522,
     MIFL = 523,
     MIFP = 524,
     MILES = 525,
     MINOR = 526,
     MINUTES = 527,
     MISSINGP = 528,
     MM = 529,
     MMDD = 530,
     MMDDHMS = 531,
     MMDDYY = 532,
     MMDDYYHMS = 533,
     MMSSLAT = 534,
     MMSSLON = 535,
     MMYY = 536,
     MONTHDAY = 537,
     MONTHL = 538,
     MONTHS = 539,
     MOVE = 540,
     MOVE2 = 541,
     MOVETO = 542,
     NEGATE = 543,
     NO = 544,
     NODE = 545,
     NODES = 546,
     NONE = 547,
     NORMAL = 548,
     NORTH = 549,
     NXY = 550,
     OFF = 551,
     OFFSETX = 552,
     OFFSETY = 553,
     ON = 554,
     OP = 555,
     OPEN = 556,
     ORIENT = 557,
     OUT = 558,
     PAGE = 559,
     PARA = 560,
     PARALLEL = 561,
     PARAMETERS = 562,
     PARAMS = 563,
     PARMS = 564,
     PATTERN = 565,
     PER = 566,
     PERIMETER = 567,
     PERP = 568,
     PERPENDICULAR = 569,
     PHASE = 570,
     PIE = 571,
     PIPE = 572,
     PLACE = 573,
     PLAN = 574,
     PLUS = 575,
     POINT = 576,
     POLAR = 577,
     POLY = 578,
     POLYI = 579,
     POLYO = 580,
     POP = 581,
     POWER = 582,
     PREC = 583,
     PREFIX = 584,
     PREPEND = 585,
     PRINT = 586,
     PROFILE = 587,
     PROP = 588,
     PS = 589,
     PSCOLORL = 590,
     PSCOLORP = 591,
     PSMONOL = 592,
     PSMONOP = 593,
     PUSH = 594,
     PUTP = 595,
     QUIT = 596,
     READ = 597,
     READBIN = 598,
     REDRAW = 599,
     REGION = 600,
     REGIONS = 601,
     REGNUM = 602,
     REGRESS = 603,
     REMOVE = 604,
     RENDER = 605,
     REPORT = 606,
     RESET = 607,
     REVERSE = 608,
     REWIND = 609,
     RIGHT = 610,
     RISER = 611,
     ROT = 612,
     RUN = 613,
     SALINITY = 614,
     SAMPLE = 615,
     SAVE = 616,
     SCALAR = 617,
     SCALE = 618,
     SCIENTIFIC = 619,
     SECONDS = 620,
     SET = 621,
     SETS = 622,
     SHOW = 623,
     SHRINK = 624,
     SIGMA = 625,
     SIGN = 626,
     SIZE = 627,
     SKIP = 628,
     SLAB = 629,
     SLEEP = 630,
     SLICE = 631,
     SOURCE = 632,
     SPEC = 633,
     SPECIFIED = 634,
     SPECTRUM = 635,
     SPLITS = 636,
     SQUARE = 637,
     STACK = 638,
     STACKEDBAR = 639,
     STACKEDHBAR = 640,
     STACKEDLINE = 641,
     STAGGER = 642,
     STAR = 643,
     START = 644,
     STARTSTEP = 645,
     STARTTYPE = 646,
     STATION = 647,
     STATUS = 648,
     STEP = 649,
     STOP = 650,
     STREAMLINES = 651,
     STRING = 652,
     STRINGS = 653,
     SUBTITLE = 654,
     SURFACE = 655,
     SWAPBUFFER = 656,
     SYMBOL = 657,
     SYSTEM = 658,
     TEANL = 659,
     TEXT = 660,
     TICK = 661,
     TICKLABEL = 662,
     TICKMARKS = 663,
     TICKP = 664,
     TIDALCLOCK = 665,
     TIDESTATION = 666,
     TIME = 667,
     TIMEINFO = 668,
     TIMELINE = 669,
     TITLE = 670,
     TO = 671,
     TOP = 672,
     TOTAL = 673,
     TRACK = 674,
     TRANSECT = 675,
     TRIANGLE1 = 676,
     TRIANGLE2 = 677,
     TRIANGLE3 = 678,
     TRIANGLE4 = 679,
     TRUEP = 680,
     TYPE = 681,
     UNITS = 682,
     UP = 683,
     VALUE = 684,
     VECTOR = 685,
     VEL = 686,
     VELMARKER = 687,
     VELOCITY = 688,
     VERTICAL = 689,
     VGAP = 690,
     VIEW = 691,
     VSCALE = 692,
     VX1 = 693,
     VX2 = 694,
     VY1 = 695,
     VY2 = 696,
     WEEKS = 697,
     WET = 698,
     WETDRY = 699,
     WIDTH = 700,
     WIND = 701,
     WITH = 702,
     WORLD = 703,
     WRAP = 704,
     WRITE = 705,
     WSCALE = 706,
     WX1 = 707,
     WX2 = 708,
     WY1 = 709,
     WY2 = 710,
     X0 = 711,
     X1 = 712,
     X2 = 713,
     X3 = 714,
     X4 = 715,
     X5 = 716,
     XAXES = 717,
     XAXIS = 718,
     XCOR = 719,
     XMAX = 720,
     XMIN = 721,
     XY = 722,
     XYARC = 723,
     XYBOX = 724,
     XYDX = 725,
     XYDXDX = 726,
     XYDXDY = 727,
     XYDY = 728,
     XYDYDY = 729,
     XYFIXED = 730,
     XYHILO = 731,
     XYRT = 732,
     XYSEG = 733,
     XYSTRING = 734,
     XYUV = 735,
     XYX2Y2 = 736,
     XYXX = 737,
     XYYY = 738,
     XYZ = 739,
     XYZW = 740,
     Y0 = 741,
     Y1 = 742,
     Y2 = 743,
     Y3 = 744,
     Y4 = 745,
     Y5 = 746,
     YAXES = 747,
     YAXIS = 748,
     YEARS = 749,
     YES = 750,
     YMAX = 751,
     YMIN = 752,
     ZEROXAXIS = 753,
     ZEROYAXIS = 754,
     ZOOM = 755,
     ZOOMBOX = 756,
     OR = 757,
     AND = 758,
     NE = 759,
     EQ = 760,
     GE = 761,
     LE = 762,
     LT = 763,
     GT = 764,
     NOT = 765,
     UMINUS = 766
   };
#endif
/* Tokens.  */
#define VAR 258
#define X 259
#define Y 260
#define CHRSTR 261
#define FITPARM 262
#define NUMBER 263
#define ABS 264
#define ACOS 265
#define ASIN 266
#define ATAN 267
#define ATAN2 268
#define CEIL 269
#define COS 270
#define DEG 271
#define DX 272
#define DY 273
#define ERF 274
#define ERFC 275
#define EXP 276
#define FLOOR 277
#define HYPOT 278
#define INDEX 279
#define INT 280
#define IRAND 281
#define LGAMMA 282
#define LN 283
#define LOG 284
#define LOGISTIC 285
#define MAXP 286
#define MINP 287
#define MINMAX 288
#define MOD 289
#define NORM 290
#define NORMP 291
#define PI 292
#define RAD 293
#define RAND 294
#define SETNO 295
#define SIN 296
#define SQR 297
#define SQRT 298
#define TAN 299
#define INUM 300
#define ABORT 301
#define ABOVE 302
#define ABSOLUTE 303
#define ACTIVATE 304
#define ACTIVE 305
#define ADCIRC 306
#define ADCIRC3DFLOW 307
#define ALL 308
#define ALT 309
#define ALTERNATE 310
#define ALTXAXIS 311
#define ALTYAXIS 312
#define AMP 313
#define ANGLE 314
#define ANNOTATE 315
#define APPEND 316
#define AREA 317
#define ARROW 318
#define ASCEND 319
#define AT 320
#define ATTACH 321
#define AUTO 322
#define AUTOSCALE 323
#define AUTOTICKS 324
#define AVERAGE 325
#define AVG 326
#define AXES 327
#define AXIS 328
#define BACKBUFFER 329
#define BACKGROUND 330
#define BAR 331
#define BATCH 332
#define BATH 333
#define BATHYMETRY 334
#define COURANT 335
#define BELOW 336
#define BIN 337
#define BINARY 338
#define BOTH 339
#define BOTTOM 340
#define BOUNDARY 341
#define BOX 342
#define CELLS 343
#define CENTER 344
#define CH3D 345
#define CHAR 346
#define CHDIR 347
#define CIRCLE 348
#define CLEAR 349
#define CLICK 350
#define CLOCK 351
#define CLOSE 352
#define CM 353
#define CMAP 354
#define COLOR 355
#define COLORMAP 356
#define COMMENT 357
#define CONC 358
#define CONCENTRATION 359
#define CONCENTRATIONS 360
#define COPY 361
#define CROSS 362
#define CYCLE 363
#define DAYMONTH 364
#define DAYOFWEEKL 365
#define DAYOFWEEKS 366
#define DAYOFYEAR 367
#define DAYS 368
#define DDMMYY 369
#define DDMONTHSYYHHMMSS 370
#define DECIMAL 371
#define DEF 372
#define DEFAULT 373
#define DEGREESLAT 374
#define DEGREESLON 375
#define DEGREESMMLAT 376
#define DEGREESMMLON 377
#define DEGREESMMSSLAT 378
#define DEGREESMMSSLON 379
#define DELAYP 380
#define DELETE 381
#define DEPTH 382
#define DEPTHS 383
#define DESCEND 384
#define DEVICE 385
#define DEVXY 386
#define DFT 387
#define DT 388
#define DIAMOND 389
#define DIFFERENCE 390
#define DISK 391
#define DISPLAY 392
#define DOT 393
#define DOUBLEBUFFER 394
#define DOWN 395
#define DRAW2 396
#define DROGUE 397
#define DROGUES 398
#define DRY 399
#define DXDX 400
#define DXP 401
#define DYDY 402
#define DYP 403
#define ECHO 404
#define EDIT 405
#define ELA 406
#define ELCIRC 407
#define ELEMENT 408
#define ELEMENTS 409
#define ELEV 410
#define ELEVATION 411
#define ELEVATIONS 412
#define ELEVMARKER 413
#define ELLIPSE 414
#define ELLIPSES 415
#define ELLIPSEZ 416
#define ELSE 417
#define END 418
#define ERRORBAR 419
#define EXIT 420
#define EXPAND 421
#define EXPONENTIAL 422
#define FACTOR 423
#define FALSEP 424
#define FAST 425
#define FEET 426
#define FFT 427
#define FILEP 428
#define FILL 429
#define FIND 430
#define FIXEDPOINT 431
#define FLOW 432
#define FLUSH 433
#define FLUX 434
#define FOCUS 435
#define FOLLOWS 436
#define FONTP 437
#define FOREGROUND 438
#define FORMAT 439
#define FORT14 440
#define FORT63 441
#define FORT64 442
#define FORWARD 443
#define FRAMEP 444
#define FREQ 445
#define FRONTBUFFER 446
#define GENERAL 447
#define GETP 448
#define GOTO 449
#define GRAPH 450
#define GRAPHNO 451
#define GRAPHS 452
#define GRAPHTYPE 453
#define GRID 454
#define HARDCOPY 455
#define HBAR 456
#define HELP 457
#define HGAP 458
#define HIDDEN 459
#define HISTBOX 460
#define HISTO 461
#define HISTORY 462
#define HMS 463
#define HORIZONTAL 464
#define HOURS 465
#define HPGLL 466
#define HPGLP 467
#define IF 468
#define IGNORE 469
#define IHL 470
#define IMAGE 471
#define IMAGES 472
#define IN 473
#define INCLUDE 474
#define INFO 475
#define INIT 476
#define INITGRAPHICS 477
#define INOUT 478
#define INTEGRATE 479
#define INTERP 480
#define INUNDATION 481
#define INVDFT 482
#define INVFFT 483
#define ISOLINE 484
#define ISOLINES 485
#define JUST 486
#define KILL 487
#define KM 488
#define LABEL 489
#define LAYOUT 490
#define LEAVE 491
#define LEAVEGRAPHICS 492
#define LEFT 493
#define LEGEND 494
#define LENGTH 495
#define LEVEL 496
#define LEVELS 497
#define LIMITS 498
#define LINE 499
#define LINES 500
#define LINESTYLE 501
#define LINETO 502
#define LINEW 503
#define LINEWIDTH 504
#define LINK 505
#define LOAD 506
#define LOC 507
#define LOCATE 508
#define LOCATOR 509
#define LOCTYPE 510
#define LOGX 511
#define LOGXY 512
#define LOGY 513
#define M 514
#define MAG 515
#define MAGNITUDE 516
#define MAJOR 517
#define MAPSCALE 518
#define MARKER 519
#define MARKERS 520
#define MAXLEVELS 521
#define METHOD 522
#define MIFL 523
#define MIFP 524
#define MILES 525
#define MINOR 526
#define MINUTES 527
#define MISSINGP 528
#define MM 529
#define MMDD 530
#define MMDDHMS 531
#define MMDDYY 532
#define MMDDYYHMS 533
#define MMSSLAT 534
#define MMSSLON 535
#define MMYY 536
#define MONTHDAY 537
#define MONTHL 538
#define MONTHS 539
#define MOVE 540
#define MOVE2 541
#define MOVETO 542
#define NEGATE 543
#define NO 544
#define NODE 545
#define NODES 546
#define NONE 547
#define NORMAL 548
#define NORTH 549
#define NXY 550
#define OFF 551
#define OFFSETX 552
#define OFFSETY 553
#define ON 554
#define OP 555
#define OPEN 556
#define ORIENT 557
#define OUT 558
#define PAGE 559
#define PARA 560
#define PARALLEL 561
#define PARAMETERS 562
#define PARAMS 563
#define PARMS 564
#define PATTERN 565
#define PER 566
#define PERIMETER 567
#define PERP 568
#define PERPENDICULAR 569
#define PHASE 570
#define PIE 571
#define PIPE 572
#define PLACE 573
#define PLAN 574
#define PLUS 575
#define POINT 576
#define POLAR 577
#define POLY 578
#define POLYI 579
#define POLYO 580
#define POP 581
#define POWER 582
#define PREC 583
#define PREFIX 584
#define PREPEND 585
#define PRINT 586
#define PROFILE 587
#define PROP 588
#define PS 589
#define PSCOLORL 590
#define PSCOLORP 591
#define PSMONOL 592
#define PSMONOP 593
#define PUSH 594
#define PUTP 595
#define QUIT 596
#define READ 597
#define READBIN 598
#define REDRAW 599
#define REGION 600
#define REGIONS 601
#define REGNUM 602
#define REGRESS 603
#define REMOVE 604
#define RENDER 605
#define REPORT 606
#define RESET 607
#define REVERSE 608
#define REWIND 609
#define RIGHT 610
#define RISER 611
#define ROT 612
#define RUN 613
#define SALINITY 614
#define SAMPLE 615
#define SAVE 616
#define SCALAR 617
#define SCALE 618
#define SCIENTIFIC 619
#define SECONDS 620
#define SET 621
#define SETS 622
#define SHOW 623
#define SHRINK 624
#define SIGMA 625
#define SIGN 626
#define SIZE 627
#define SKIP 628
#define SLAB 629
#define SLEEP 630
#define SLICE 631
#define SOURCE 632
#define SPEC 633
#define SPECIFIED 634
#define SPECTRUM 635
#define SPLITS 636
#define SQUARE 637
#define STACK 638
#define STACKEDBAR 639
#define STACKEDHBAR 640
#define STACKEDLINE 641
#define STAGGER 642
#define STAR 643
#define START 644
#define STARTSTEP 645
#define STARTTYPE 646
#define STATION 647
#define STATUS 648
#define STEP 649
#define STOP 650
#define STREAMLINES 651
#define STRING 652
#define STRINGS 653
#define SUBTITLE 654
#define SURFACE 655
#define SWAPBUFFER 656
#define SYMBOL 657
#define SYSTEM 658
#define TEANL 659
#define TEXT 660
#define TICK 661
#define TICKLABEL 662
#define TICKMARKS 663
#define TICKP 664
#define TIDALCLOCK 665
#define TIDESTATION 666
#define TIME 667
#define TIMEINFO 668
#define TIMELINE 669
#define TITLE 670
#define TO 671
#define TOP 672
#define TOTAL 673
#define TRACK 674
#define TRANSECT 675
#define TRIANGLE1 676
#define TRIANGLE2 677
#define TRIANGLE3 678
#define TRIANGLE4 679
#define TRUEP 680
#define TYPE 681
#define UNITS 682
#define UP 683
#define VALUE 684
#define VECTOR 685
#define VEL 686
#define VELMARKER 687
#define VELOCITY 688
#define VERTICAL 689
#define VGAP 690
#define VIEW 691
#define VSCALE 692
#define VX1 693
#define VX2 694
#define VY1 695
#define VY2 696
#define WEEKS 697
#define WET 698
#define WETDRY 699
#define WIDTH 700
#define WIND 701
#define WITH 702
#define WORLD 703
#define WRAP 704
#define WRITE 705
#define WSCALE 706
#define WX1 707
#define WX2 708
#define WY1 709
#define WY2 710
#define X0 711
#define X1 712
#define X2 713
#define X3 714
#define X4 715
#define X5 716
#define XAXES 717
#define XAXIS 718
#define XCOR 719
#define XMAX 720
#define XMIN 721
#define XY 722
#define XYARC 723
#define XYBOX 724
#define XYDX 725
#define XYDXDX 726
#define XYDXDY 727
#define XYDY 728
#define XYDYDY 729
#define XYFIXED 730
#define XYHILO 731
#define XYRT 732
#define XYSEG 733
#define XYSTRING 734
#define XYUV 735
#define XYX2Y2 736
#define XYXX 737
#define XYYY 738
#define XYZ 739
#define XYZW 740
#define Y0 741
#define Y1 742
#define Y2 743
#define Y3 744
#define Y4 745
#define Y5 746
#define YAXES 747
#define YAXIS 748
#define YEARS 749
#define YES 750
#define YMAX 751
#define YMIN 752
#define ZEROXAXIS 753
#define ZEROYAXIS 754
#define ZOOM 755
#define ZOOMBOX 756
#define OR 757
#define AND 758
#define NE 759
#define EQ 760
#define GE 761
#define LE 762
#define LT 763
#define GT 764
#define NOT 765
#define UMINUS 766



#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
{
/* Line 2058 of yacc.c  */
#line 113 "gram.y"

    double val;
    int ival;
    double *ptr;
    int func;
    int pset;
    char *str;


/* Line 2058 of yacc.c  */
#line 1089 "y.tab.h"
} YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif

extern YYSTYPE yylval;

#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse (void *YYPARSE_PARAM);
#else
int yyparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */

#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
