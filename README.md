Mailfull GUI - The GUI of a configuration tool for virtual domain email 
========================================================

要件
----

  * Perl 5.x.x
    * Digest::SHA1 module
  * Apache 2.x
    * mod_rewrite
    * suEXEC

クイックスタートガイド
----------------------

  MAilfullをインストール  
<https://github.com/directorz/mailfull>
  
  リポジトリ取得

    # git clone git://github.com/directorz/mailfull-gui.git /home/mailfull/gui
    # chmod 755 /home/mailfull/gui/index.pl

  suEXECのために/var/www以下をmount
    
    # cd /var/www/
    # mkdir -p /var/www/html_mailfull/
    # mount --bind /home/mailfull/gui/ /var/www/html_mailfull/
    # echo '/home/js-furniture.jp	/home/saunashi/js-furniture.jp	none	bind	0 0' >> /etc/fstab

  Apacheのconfigを作成

    # cd /home/mailfull/gui/etc
    # vi mailfullgui.conf
    * ドメインを修正
    # cp mailfullgui.conf /etc/http/conf.d/

  Apacheを再起動

    # /etc/init.d/httpd restart

  完了

詳細
----

  * ドメインマスターユーザは
  *  mailfull_master/mailfull_master でログイン可能です。
  * ユーザ、パスワードの変更は/home/mailfull/gui/const.pm を修正して下さい。

機能
----

  * ドメインマスター、postmaster、ユーザの３段階の権限があります。
  * ユーザは以下権限を持ちます
    * 自分のパスワード変更
    * 自分の.forward変更
  * postmasterは以下権限を持ちます。
    * ユーザの追加、修正、削除
    * エイリアス設定
  * ドメインマスターは以下権限を持ちます。
    * ドメインの追加、修正、削除
    * ドメインエイリアスの追加、削除

実装予定
--------

  * Apacheを利用しないサーバ
  

