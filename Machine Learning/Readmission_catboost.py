import os,  pandas as pd,  numpy as np
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import StratifiedKFold
from catboost import CatBoostClassifier
from hyperopt import fmin, hp, tpe, STATUS_OK, Trials
import tsfresh as tsf

analysis = pd.read_sas('Dataset/combined_vars_04092019.sas7bdat', encoding='latin1').drop(['TRR_ID', 'TRANSPLANT_DT', 'TRANSPLANT_DISCHARGE_DT', 'READMISSION_DT'], axis=1)
biomarker = pd.read_csv('Dataset/feature_extracted_365days.csv')
# X = biomarker.drop('PERSON_ID', 1)
X = analysis.merge(biomarker, on='PERSON_ID').drop(['CODE_REHOSP', 'PERSON_ID'], 1)
y = analysis['CODE_REHOSP'].replace(2, 0)
cat_colidx = [X.columns.get_loc(col) for col in X.columns if X[col].nunique() <= 10]

for col in cat_colidx:
    if X[X.columns[col]].dtype == 'float64':
        X[X.columns[col]] = X[X.columns[col]].fillna(-1).astype(int)
    else:
        X[X.columns[col]] = X[X.columns[col]].fillna('')

cbc_params = {
    'max_depth': hp.choice('max_depth', np.arange(2, 11)),
    'l2_leaf_reg': hp.uniform('l2_leaf_reg', 0, 500),
    'colsample_bylevel': hp.uniform('colsample_bylevel', 0.1, 1),
#     'subsample': hp.uniform('subsample', 0.1, 1),
    'eta': hp.uniform('eta', 0.01, 0.1),
#     'bootstrap_type': hp.choice('bootstrap_type', ['Bernoulli', 'Poisson', 'No']),
#     'one_hot_max_size': hp.choice('one_hot_max_size', np.arange(2,6))
}

def f_cbc(params):
    kfold = StratifiedKFold(5, True, 2019)
    auc = np.zeros(kfold.get_n_splits())
    cbc_pred = np.zeros(len(X))
    featureimp = np.zeros(X.shape[1])
    cbc = CatBoostClassifier(
        **params,
        n_estimators=999999,
        random_state=2019,
        eval_metric='AUC',
        cat_features=cat_colidx,
        silent=True,
        one_hot_max_size=2,
#         bootstrap_type='Bernoulli',
#         boosting_type='Plain',
#         task_type='GPU',
    )
    for i, (tr_idx, val_idx) in enumerate(kfold.split(X, y)):
        clf = cbc.fit(X.iloc[tr_idx],
                      y[tr_idx],
                      use_best_model=True,
                      eval_set=(X.iloc[val_idx], y[val_idx]),
                      early_stopping_rounds=200,
                      verbose_eval=False)
        cbc_pred[val_idx] = clf.predict_proba(X.iloc[val_idx])[:, 1]
        featureimp += np.asarray(clf.get_feature_importance()) / kfold.n_splits
        auc[i] = roc_auc_score(y[val_idx], cbc_pred[val_idx])
        # print("Mean AUC(%g|%g): %.5f" %(i, kfold.get_n_splits(), np.sum(auc)/i))
    return {'loss': -np.mean(auc).round(5), 'status': STATUS_OK, 'featureimp': featureimp}

trials = Trials()
cbc_best = fmin(f_cbc, cbc_params, algo=tpe.suggest, rstate=np.random.RandomState(9012), max_evals=10, trials=trials)

imp = pd.DataFrame({'features': X.columns, 'importance': trials.best_trial['result']['featureimp']}).sort_values('importance', ascending=False)

