#!/usr/bin/python

# encoding: utf-8

'''

@author: Jiadong Lin

@contact: jiadong324@gmail.com

@time: 24/11/2017
'''
import sys
import os
import numpy as np
import pandas as pd
from sklearn.manifold import TSNE
import seaborn as sns
import matplotlib.pylab as plt

#from ggplot import *
data_path = "/public/home/ybkliuyf/project/IRseq/Plot_TSNE/NewDir/"


def tsne(pdData, vjFamily, figurePath, xyPath):
    #fig = plt.figure()
    print("Start:")
    global tsne_results
    try:
        tsne = TSNE(n_components=2, verbose=1, perplexity=40, n_iter=300)
        tsne_results = tsne.fit_transform(pdData.values)
    except:
        massage = "tsne not applicable"
        print (massage)

    df_tsne = pdData.copy()
    df_tsne['x'] = tsne_results[:, 0]
    df_tsne['y'] = tsne_results[:, 1]
    #sns.lmplot('x', 'y', data = df_tsne, fit_reg = False, scatter_kws = {'color': 'b'})
    #plt.title(vjFamily)
    #plt.savefig(figurePath + '/' + vjFamily + '.png', dpi = fig.dpi)
    # chart = ggplot(df_tsne, aes(x='x', y='y', color='label')) + geom_point(size=70, alpha=0.1)
    #print('AAAAAA: vj-family',vjFamily)
    pd.set_option('display.width',None)
    pd.set_option('display.max_rows',10000)
    #pd.set_option('display.height',None)
    pd.set_option('display.max_colwidth',10000)
    pd.set_option('display.max_columns',15000)
#    print ('test:row:col:  ',df_tsne)
    writer = open(xyPath + '/' + vjFamily + '.coords.txt','w')
    np.set_printoptions(threshold=np.NaN)
    outStr = 'X: {0}\nY: {1}\n'.format(tsne_results[:, 0], tsne_results[:, 1])
#    writer.write(outStr)
    print(outStr,file=writer)
    writer.close()

def main():
    sample = sys.argv[1]
#    for dir in os.listdir(data_path):
    subpath = data_path + "/" + sample
    if os.path.isdir(subpath):
#            print ('===== Processing sample: ', dir)
        for file in os.listdir(subpath):
            file_extension = file.split('.')[-1]
            if file_extension == 'xls':
                dist_file = subpath + '/' + file                    
                vjFamily = file.split('.')[1]
                print ('calculate and plot vj-family: ', vjFamily)
                print ('Dist File: ', dist_file)
                pdData = pd.read_csv(dist_file, index_col=0, delimiter='\t')
                print (pdData.shape[0],pdData.isnull().any().sum())
                if not pdData.isnull().any().any() and pdData.shape[0] > 1:
                    #if pdData.shape[0] > 1:
                    tsne(pdData, vjFamily, subpath, subpath)

if __name__ == '__main__':
    main()
    pass
