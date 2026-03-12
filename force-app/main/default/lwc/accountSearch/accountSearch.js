/**
 * @description 取引先検索コンポーネントのロジック
 */
// LWCの基本クラス、wire、apiデコレータをインポートする
import { LightningElement, wire, api } from 'lwc';
// Apexクラスのメソッドをインポートする
import getAccounts from '@salesforce/apex/AccountSearchController.getAccounts';
// オブジェクト情報の取得用アダプタをインポートする
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
// 選択リスト値の取得用アダプタをインポートする
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
// Accountオブジェクトの参照をインポートする
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
// Industry項目の参照をインポートする
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';

// データテーブルの列定義を行う定数
const COLUMNS = [
    { label: '取引先名', fieldName: 'Name' },
    { label: '請求先都道府県', fieldName: 'BillingState' },
    { label: '請求先市区町村', fieldName: 'BillingCity' },
    { label: '業種', fieldName: 'Industry' },
    { label: '従業員数', fieldName: 'NumberOfEmployees', type: 'number' },
    { label: '所有者', fieldName: 'OwnerName' } // JSでフラット化する項目
];

export default class AccountSearch extends LightningElement {
    // 外部から設定可能な初期値プロパティ（ビルダー設定用）
    // 初期値の代入を外し、宣言のみに変更
    @api initialAccountName;
    @api initialIndustry;

    // 検索用：取引先名を保持するプロパティ（内部管理用）
    searchName = '';
    // 検索用：業種を保持するプロパティ（内部管理用）
    searchIndustry = '';
    // 検索結果の取引先リストを保持するプロパティ
    accounts; // undefinedで初期化
    // エラーメッセージを保持するプロパティ
    error;
    // データテーブルの列定義をプロパティに設定する
    columns = COLUMNS;
    // AccountオブジェクトのレコードタイプIDを保持する
    recordTypeId;
    // 業種の選択肢リストを保持する
    industryOptions = [];

    /**
     * コンポーネント初期化時のライフサイクルフック
     * ビルダーで設定された値を内部プロパティに反映する
     */
    connectedCallback() {
        // 取引先名の初期値があればセットする
        if (this.initialAccountName) {
            this.searchName = this.initialAccountName;
        }
        // 業種の初期値があればセットする
        if (this.initialIndustry) {
            this.searchIndustry = this.initialIndustry;
        }
    }

    /**
     * Accountオブジェクトの情報を取得するWire
     * デフォルトのレコードタイプIDを取得するために使用する
     */
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            // デフォルトレコードタイプIDを取得して設定する
            this.recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            // エラーが発生した場合、コンソールに出力する
            console.error('Error fetching object info', error);
        }
    }

    /**
     * 業種項目の選択リスト値を取得するWire
     * レコードタイプIDが取得できた後に動作する
     */
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: INDUSTRY_FIELD })
    wiredPicklistValues({ error, data }) {
        if (data) {
            // 取得した選択リスト値をcombobox用の形式にマップする
            this.industryOptions = data.values.map(plValue => {
                return { label: plValue.label, value: plValue.value };
            });
            // 先頭に「なし」の選択肢を追加する場合の処理（今回は省略）
        } else if (error) {
            // エラーが発生した場合、コンソールに出力する
            console.error('Error fetching picklist values', error);
        }
    }

    /**
     * 名前入力欄の変更ハンドラ
     * @param event 入力イベント
     */
    handleNameChange(event) {
        // 入力された値をプロパティにセットする
        this.searchName = event.target.value;
    }

    /**
     * 業種選択リストの変更ハンドラ
     * @param event 変更イベント
     */
    handleIndustryChange(event) {
        // 選択された値をプロパティにセットする
        this.searchIndustry = event.target.value;
    }

    /**
     * 検索ボタンクリック時のハンドラ
     * Apexメソッドを命令的(Imperative)に呼び出す
     */
    handleSearch() {
        // エラー状態を初期化する
        this.error = undefined;
        // 結果リストを初期化する
        this.accounts = undefined;

        // Apexメソッドを呼び出す
        getAccounts({ accountName: this.searchName, industry: this.searchIndustry })
            .then(result => {
                // 結果データをマップし、所有者名をフラット化する
                this.accounts = result.map(record => {
                    // 各レコードのオブジェクトをコピーし、新しいプロパティを追加する
                    return {
                        ...record,
                        // 所有者名をルートレベルのプロパティとして設定する
                        OwnerName: record.Owner ? record.Owner.Name : ''
                    };
                });
            })
            .catch(error => {
                // エラーが発生した場合、エラーメッセージを設定する
                this.error = 'データの取得中にエラーが発生しました。';
                // コンソールに詳細を出力する
                console.error(error);
            });
    }

    /**
     * 検索結果が空かどうかを判定するゲッター
     * accounts配列が存在し、かつ長さが0の場合にtrueを返す
     */
    get isEmpty() {
        return this.accounts && this.accounts.length === 0;
    }
}