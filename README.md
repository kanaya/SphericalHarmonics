# SphericalHarmonics

2012-11-23  
Ichi Kanaya

## 概要
SphericalHarmonics は全天画像を球面調和函数変換するためのプログラムです（でした）．オリジナルは金谷一朗によって2004年に Mac OS X 向けに書かれたものです．

このパッケージは，オリジナルをそのまま収録すると共に，球面調和変換函数変換係数のみ抜き出しライブラリ化したものも収録します．

なお，本実装の球面調和函数変換関数は [GNU Scientific Library](http://www.gnu.org/software/gsl/) 1.4 およびメルセンヌ・ツイスタ2002年版に依存しています．互換性のため，メルセンヌ・ツイスタ2002年版を本パッケージに同梱しています．

## やっていること
球面調和函数を Y_l^m(\alpha,\beta) とします．本パッケージの関数（球面調和函数変換関数）は，全天画像が f(\alpha,\beta) で与えられたとすると，これを f(\alpha,\beta)=\sum_{l=0}^\infty\sum_{m=-l}^{+l}c_l^mY_l^m(\alpha,\beta) となるような球面調和函数係数 c_l^m に分解します．


## パッケージ構成

### SphericalHarmonicsCore

球面調和函数変換関数です．

    void comp_spherical_harmonics_coeffs(double *sh_coeffs, int n_bands, const double *image, int sqrt_n_pixels, const double *sampling_points, int n_sampling_points);

全天画像から球面調和函数変換係数を計算する関数です．モンテカルロ法を使います．

`sh_coeffs`: 球面調和係数を入れる配列．呼び出し側でメモリ確保する必要があります．配列長はバンド数（次数） `n_bands` の2乗で，バンドl，方向mの球面調和係数は配列の l * (l + 1) + m 番に格納されます．

`n_bands`: 球面調和係数を何バンド（何次）まで計算するかの指定．

`image`: 全天画像．画像は `sqrt_n_pixels` x `sqrt_n_pixels` ピクセルの正方形で，内接円内部のみが利用されます．1次元配列として与えます．

`sqrt_n_pixels`: 画像 `image` の1辺のピクセル数です．

`sampling_points`: モンテカルロ法のサンプリングポイント．オイラー角α，β（座標系のとり方はCoordinateSystem.pdfをご参照下さい）を並べた1次元配列で，配列長は `n_sapmling_points` の2倍です．

`n_sampling_points`: モンテカルロ法のサンプリング数．

    void comp_image(double *image, int sqrt_n_pixels, const double *sh_coeffs, int n_bands);

バンド数（次数）が `n_bands` の球面調和係数 `sh_coeffs` から解像度が `n_pixels` x `n_pixels` の画像 `image` を生成する関数．画像 `image` は呼び出し側で確保しておく必要があります．

    void comp_spherical_harmonics_coeffs_step_by_step(double *sh_coeffs, int n_bands, const double *image, int sqrt_n_pixels, double alpha, double beta);

`comp_spherical_harmonics_coeffs` の逐次実行バージョンです．1回の呼び出しで，モンテカルロ法の1ステップを実行します．

    double comp_pixel(int x, int y, int sqrt_n_pixels, const double *sh_coeffs, int n_bands);

`comp_image` の逐次実行バージョンです．1回の呼び出しで，1ピクセル分のみ計算します．

    void clip_image(double *image, int sqrt_n_pixels);

関係ないピクセルを0で埋める関数．

    void scale_image(double *image, int sqrt_n_pixels);

画像の画素値の最大を1になるように画像を正規化する関数．画像は1次元配列で，画素値はdouble型で与えます．画像のサイズは `sqrt_n_pixel` x `sqrt_n_pixel` です．

    void normalize_image(double *image, int sqrt_n_pixels);

画像の画素値の合計が1になるように画像を正規化する関数．画像は1次元配列で，画素値はdouble型で与えます．画像のサイズは `sqrt_n_pixel` x `sqrt_n_pixel` です．

    void setup_uniform_hemispherical_dist(double *dist, int n_points);

モンテカルロ法のためのオイラー角値ランダム生成関数．配列 `dist` は呼び出し側でメモリを確保する必要があります．配列 `dist` にはα，β，α，β，・・・とランダムな値が格納されます．配列 `dist` の配列長は `n_points` の2倍です．

    void setup_weighted_hemispherical_dist(double *dist, int n_points, const double *image, int sqrt_n_pixels);

モンテカルロ法のためのオイラー角値ランダム生成函数．ピクセル数が `sqrt_n_pixels` x `sqrt_n_pixels` の正方形に内接する全天画像で，画素値の最大値が1であるように正規化された画像を `image` に与えると，画素値の大きさにほぼ比例した importance sampling を行います．


### MersenneTwister

松本眞 [Mersenne Twister with improved initialization (2002)](http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/mt19937ar.html) に configure スクリプトを追加したものです．

### SphericalHaromincs

Mac OS X 用のアプリケーションです．全天画像を読み込んで，球面調和係数，および逆変換を書くにすることが出来るアプリケーションです（でした）．OS X 10.8 ではビルドに失敗します．