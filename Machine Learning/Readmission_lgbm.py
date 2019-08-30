import os,  pandas as pd,  numpy as np, gc
from matplotlib import pyplot as plt
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import StratifiedKFold, cross_val_score
from sklearn.preprocessing import LabelEncoder
from sklearn.impute import SimpleImputer
from hyperopt import fmin, hp, tpe, STATUS_OK, Trials
import lightgbm as lgbm
import warnings
warnings.filterwarnings("ignore")


##import data from sasfile

analysis = pd.read_sas('Dataset/combined_vars_04092019.sas7bdat', encoding='latin1').drop(
    ['TRR_ID', 'TRANSPLANT_DT', 'TRANSPLANT_DISCHARGE_DT', 'READMISSION_DT'], axis=1)
biomarker = pd.read_csv('Dataset/feature_extracted.csv').drop('CODE_REHOSP', 1)
X = analysis.merge(biomarker, on='PERSON_ID').drop(['CODE_REHOSP', 'PERSON_ID'], 1)
y = analysis['CODE_REHOSP'].replace(2, 0)
cat_col = [X.columns.get_loc(col) for col in X.columns if 2 < X[col].nunique() <= 10]

for col in X.columns:
    if X[col].dtype == 'O':
        X[col] = LabelEncoder().fit_transform(X[col].fillna('Unknown'))
    elif 2 < X[col].nunique() <= 10:
        X[col] = LabelEncoder().fit_transform(X[col].fillna(99))


####################################################################
# model fitting
####################################################################

# lgbm
lgbm_param = {
    'num_leaves': hp.choice('num_leaves', np.arange(2, 11)),
    'learning_rate': hp.uniform('learning_rate', 0.01, 0.1),
    'feature_fraction': hp.uniform('feature_fraction', 0.05, 0.5),
    'max_depth': hp.choice('max_depth', np.arange(2, 21)),
    'objective': 'binary',
    'boosting_type': 'gbdt',
    'metric': 'auc',
    'verbose': -1,
}


def f_lgbm(params):
    lgbm_pred = np.zeros((len(X),))
    auc = np.zeros(5)
    for i, (tr_idx, te_idx) in enumerate(StratifiedKFold(5, True, 2019).split(X, y)):
        tr_data = lgbm.Dataset(X.values[tr_idx], y.ravel()[tr_idx], categorical_feature=cat_col)
        te_data = lgbm.Dataset(X.values[te_idx], y.ravel()[te_idx], categorical_feature=cat_col)
        clf = lgbm.train(params,
                         tr_data,
                         num_boost_round=9999999,
                         verbose_eval=False,
                         valid_sets=[tr_data, te_data],
                         early_stopping_rounds=500,
                         )
        lgbm_pred[te_idx] = clf.predict(X.values[te_idx], num_iteration=clf.best_iteration)
        auc[i] = roc_auc_score(y.ravel()[te_idx], lgbm_pred[te_idx])
        del clf
        gc.collect()
    return {'loss': -np.mean(auc).round(5), 'status': STATUS_OK}

trials = Trials()
lgbm_best = fmin(f_lgbm, lgbm_param, algo=tpe.suggest, rstate=np.random.RandomState(2019), max_evals=100, trials=trials)





# plot histogram
# f, ax = plt.subplots(6, 8, figsize=(15, 20))
# for i in range(6):
#     for j in range(8):
#         try:
#             ax[i, j].set_title(normalized_var[i * 8 + j], fontsize=8)
#             ax[i, j].hist(analysis[normalized_var[i*8+j]], 20, fc='gray', ec='black', linewidth=1.2)
#             ax[i, j].xaxis.set_tick_params(labelsize=6)
#             ax[i, j].yaxis.set_tick_params(labelsize=6)
#         except:
#             f.delaxes(ax[i, j])
# plt.tight_layout()
# plt.close('all')
#
# # plot countbar
# f, ax = plt.subplots(5, 8, figsize=(15, 20))
# for i in range(5):
#     for j in range(8):
#         try:
#             ax[i, j].set_title(dummy_coded_var[i * 8 + j], fontsize=8)
#             (analysis[dummy_coded_var[i * 8 + j]].value_counts()/len(analysis)).plot(kind='bar', ax=ax[i, j])
#             ax[i, j].xaxis.set_tick_params(labelsize=6)
#             ax[i, j].yaxis.set_tick_params(labelsize=6)
#         except:
#             f.delaxes(ax[i, j])
# plt.tight_layout()
#
# plt.close('all')


