# ModalArchitecture

* iOSDC Japan 2023（2023年9月1日）で発表するトーク「モーダルの遷移を理解する」のサンプルコード
* SwiftUIのモーダルで起きる問題点を考慮し対策を行なった例
* 問題が起きる実装のリポジトリは[こちら](https://github.com/objective-audio/ModalProblem)

## モーダルの問題点

* モーダルの遷移中にisPresentedなどのモーダルのデータソースを変更すると様々な問題が起きる
  * モーダルを開こうとして開けないとViewとデータソースの整合性が取れなくなり、2度と開けなくなる
  * データソースを変更するタイミングによって、クラッシュやフリーズが起きる
  * iOS15以前で複数階層のモーダルを同時に閉じれない
  * MenuにはisPresentedのような表示の状態を管理するAPIがない

## モーダルの問題を解決する

* iOS16以降に限定する
* 同じ階層から表示するモーダルのデータソースを1つの値にまとめて、データソース的に不整合が起きないようにする
* モーダルの遷移中にViewがバインドするデータソースを変更せず、遷移中は予約しておいて、遷移が終わってから反映する
* モーダルを開いたまま別のモーダルを開くことはせず、閉じてから開くようにする
* Menuは親のViewから入れ替えることでモーダルを閉じれる
* Menuのモーダルを閉じるのと同時に他のモーダルを開けないので、モーダルの遷移開始を遅らせる
