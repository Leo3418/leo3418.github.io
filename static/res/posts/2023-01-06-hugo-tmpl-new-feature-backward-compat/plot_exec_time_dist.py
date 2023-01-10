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
        20.843343, 17.97466 , 20.916035, 21.813846, 28.113151,
        17.310946, 23.29696 , 20.942715, 27.327393, 26.188482,
    ]
    series2 = [
        13.876398,  9.453452, 10.339717, 10.727788,  9.777874,
         9.753709, 10.858828, 12.769683, 10.897951, 10.785715,
    ]
    create_plot(file_name, annotations, series1, series2)


if __name__ == '__main__':
    main()
