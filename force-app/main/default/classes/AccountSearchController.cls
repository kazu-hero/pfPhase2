/**
 * @description 取引先検索用コントローラクラス
 * クラスには "with sharing" を付与し、ユーザの権限設定を遵守する
 */
public with sharing class AccountSearchController {

    /**
     * @description 名前と業種に基づいて取引先を検索するメソッド
     * @param accountName 検索する取引先名 (部分一致用)
     * @param industry 検索する業種
     * @return List<Account> 検索結果の取引先リスト
     * LWCから呼び出すため @AuraEnabled を付与する
     * 読み取り専用でキャッシュ可能にするため cacheable=true を設定する
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(String accountName, String industry) {
        // SOQLクエリを格納する変数を定義する
        String query = 'SELECT Id, Name, BillingState, BillingCity, Industry, NumberOfEmployees, Owner.Name FROM Account';
        
        // 動的な条件構築用リストを定義する
        List<String> conditions = new List<String>();
        
        // バインド変数用の変数を定義（スコープ確保のため）
        String searchNameLike;

        // 名前が入力されている場合、条件リストに追加する
        if (String.isNotBlank(accountName)) {
            // 部分一致用にワイルドカードを付与する
            searchNameLike = '%' + accountName + '%';
            // 部分一致の条件を追加する（バインド変数を使用）
            conditions.add('Name LIKE :searchNameLike');
        }

        // 業種が選択されている場合、条件リストに追加する
        if (String.isNotBlank(industry)) {
            // 業種の一致条件を追加する
            conditions.add('Industry = :industry');
        }

        // 条件が存在する場合、WHERE句を結合してクエリに追加する
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        // クエリを実行し、結果を返す
        return Database.query(query);
    }
}