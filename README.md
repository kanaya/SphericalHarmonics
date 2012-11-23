# SphericalHarmonics

2012-11-23  
Ichi Kanaya

## 概要
SphericalHarmonics は全天画像を球面調和変換するためのプログラムです（でした）．オリジナルは金谷一朗によって2004年に Mac OS X 向けに書かれたものです．

このパッケージは，オリジナルをそのまま収録すると共に，球面調和変換関数のみ抜き出しライブラリ化したものも収録します．

なお，本実装の球面調和変換関数は GNU Scientific Library 1.4 およびメルセンヌ・ツイスタ2002年版に依存しています．互換性のため，メルセンヌ・ツイスタ2002年版を本パッケージに同梱しています．

## パッケージ構成

### SphericalHarmonicsCore

球面調和変換関数です．

### MersenneTwister

松本眞 [Mersenne Twister with improved initialization (2002)](http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/mt19937ar.html) に configure スクリプトを追加したものです．

### SphericalHaromincs

Mac OS X 用のアプリケーションです．全天画像を読み込んで，球面調和係数，および逆変換を書くにすることが出来るアプリケーションです（でした）．OS X 10.8 ではビルドに失敗します．