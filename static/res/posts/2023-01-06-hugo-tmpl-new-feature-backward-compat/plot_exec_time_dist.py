#!/usr/bin/env python

import matplotlib.pyplot as plt
import numpy as np
import scipy.stats
import sys


def get_plot_domain(series_measures, step=0.1, sigmas=4):
    lower_bound = sys.maxsize
    upper_bound = -sys.maxsize
    for mean, std_dev in series_measures:
        lower_bound = min(lower_bound, mean - sigmas * std_dev)
        upper_bound = max(upper_bound, mean + sigmas * std_dev)
    return np.arange(lower_bound, upper_bound, step)


def create_plot(file_name, annotations, *series):
    series_measures = list(map(lambda d: (np.mean(d), np.std(d)), series))
    x = get_plot_domain(series_measures)
    ax = plt.figure().add_subplot()
    for i, data in enumerate(series):
        mean, std_dev = series_measures[i]
        plt.plot(x, scipy.stats.norm.pdf(x, mean, std_dev))
    ax.set_xlabel(annotations['x'])
    ax.set_ylabel(annotations['y'])
    plt.legend(annotations['legend'])
    plt.savefig(file_name)


def main():
    file_name = 'exec-time-dist.png'
    annotations = {
        'x': "t (ms)",
        'y': "p(t)",
        'legend': [".Ancestors: \u2718", ".Ancestors: \u2714"],
    }
    series1 = [
        23.360982, 25.673855, 16.676426, 21.724248, 21.823904,
        23.215258, 20.530041, 19.765254, 19.293112, 26.525782,
    ]
    series2 = [
        11.581039,  9.629813, 14.392727,  9.619406, 10.613697,
        11.262963, 10.649529, 13.811549,  9.685682, 11.274625,
    ]
    create_plot(file_name, annotations, series1, series2)


if __name__ == '__main__':
    main()
