""" This module contains an implementation of a Vantage Point-tree (VP-tree)."""
import numpy as np


class VPTree:

    """ VP-Tree data structure for efficient nearest neighbor search.

    The VP-tree is a data structure for efficient nearest neighbor
    searching and finds the nearest neighbor in O(log n)
    complexity given a tree constructed of n data points. Construction
    complexity is O(n log n).

    Parameters
    ----------
    points : Iterable
        Construction points.
    dist_fn : Callable
        Function taking to point instances as arguments and returning
        the distance between them.
    leaf_size : int
        Minimum number of points in leaves (IGNORED).
    """

    def __init__(self, points, dist_fn):
        self.left = None  # 结点左子树
        self.right = None
        self.left_min = np.inf  # 结点左子树中的数据点到结点的vp点的最小距离
        self.left_max = 0
        self.right_min = np.inf
        self.right_max = 0
        self.dist_fn = dist_fn  # dist_fn:定义距离的函数

        if not len(points):
            raise ValueError('Points can not be empty.')

        # Vantage point is point furthest from parent vp.  优势点是离父vp最远的点。
        vp_i = 0
        self.vp = points[vp_i]  # 选取数据点中第一个作为vp
        points = np.delete(points, vp_i, axis=0)  # 更新数据点

        if len(points) == 0:
            return

        # Choose division boundary at median of distances.求距离的中位数作为划分边界。
        distances = [self.dist_fn(self.vp, p) for p in points]  # dist_fn(self.vp,p)：返回p中的点到vp的距离,是一个数组
        median = np.median(distances)  # 求距离数组的中位数

        left_points = []
        right_points = []
        for point, distance in zip(points, distances):  # zip：打包函数，返回一个元组，元组中每个元素为一对(point,distance);
            if distance >= median:  # 如果距离大于等于中位数，就更新右子树中的最小距离，最大距离，并分情况将该点插入右子树
                self.right_min = min(distance, self.right_min)
                if distance > self.right_max:  # 如果距离大于右子树中最大距离，则更新右子树中最大距离，并将该点插入列表头部
                    self.right_max = distance
                    right_points.insert(0, point)  # put furthest first  在右子树列表中，始终将到vp点距离最远的点放在列表头部，与39行相对应：
                                                   # 39行中选取数据点中第一个作为vp点，也就是始终选取离父vp最远的点作为当前vp点。
                else:  # 否则将该点插入列表尾部
                    right_points.append(point)
            else:
                self.left_min = min(distance, self.left_min)  # 此时距离小于中位数，首先更新左子树中最小距离
                if distance > self.left_max:  # 如果距离大于左子树中最大距离，则更新左子树中最大距离，并将该点插入列表头部
                    self.left_max = distance
                    left_points.insert(0, point)  # put furthest first  左子树列表中，始终将到vp点距离最远的点放在列表头部
                else:  # 否则将该点插入列表尾部
                    left_points.append(point)

        if len(left_points) > 0:  # 递归建树时，取列表中第一个点作为vp点，也就是到上一个vp点距离最远的点
            self.left = VPTree(points=left_points, dist_fn=self.dist_fn)

        if len(right_points) > 0:
            self.right = VPTree(points=right_points, dist_fn=self.dist_fn)

    def _is_leaf(self):
        return (self.left is None) and (self.right is None)

    def get_nearest_neighbor(self, query):
        """ Get single nearest neighbor.
        
        Parameters
        ----------
        query : Any
            Query point.

        Returns
        -------
        Any
            Single nearest neighbor.
        """
        return self.get_n_nearest_neighbors(query, n_neighbors=1)[0]  # 返回查询点的n_neighbors近邻中的第一个，也就是最近邻

    def get_n_nearest_neighbors(self, query, n_neighbors):  # 输入查询点以及要求的近邻数目，返回查询点的相应近邻
        """ Get `n_neighbors` nearest neigbors to `query`
        
        Parameters
        ----------
        query : Any
            Query point.
        n_neighbors : int
            Number of neighbors to fetch.

        Returns
        -------
        list
            List of `n_neighbors` nearest neighbors.
        """
        if not isinstance(n_neighbors, int) or n_neighbors < 1:
            raise ValueError('n_neighbors must be strictly positive integer')
        neighbors = _AutoSortingList(max_size=n_neighbors)  # 近邻列表，能自动排序；
        nodes_to_visit = [(self, 0)]  # 待访问的结点列表，开始时设为根结点；

        furthest_d = np.inf  # 将最大距离设为正无穷

        while len(nodes_to_visit) > 0:
            node, d0 = nodes_to_visit.pop(0)  # 当有结点需要访问时，弹出一个结点；
            if node is None or d0 > furthest_d:  # d0大于最大距离表示红圈与该结点的左右子树都没有交集，因此直接跳过该结点。
                continue

            d = self.dist_fn(query, node.vp)  # 计算查询点到当前结点的vp的距离

            # 先处理近邻列表:furthest_d为当前搜索半径，当dist<furthest_d时，就将该点插入近邻列表
            if d < furthest_d:  # 如果距离小于当前搜索半径，则将该结点插入近邻列表尾部；并更新搜索半径
                neighbors.append((d, node.vp))  # 向近邻列表中插入一对（当前结点的vp到查询点的距离，当前结点的vp）
                furthest_d, _ = neighbors[-1]  # neighbors中元素按d的值从小到大自动排序，取最后一个元素中的d值，也就是将
                # 搜索半径更新为当前近邻列表中最大的距离。只有当近邻列表中d的最大值减小时，搜索半径才会减小。比如寻找3近
                # 邻，现在往近邻列表中插入第四个元素，该元素到查询点的距离是最小的，因此排序后删除原列表中的第三个元素，
                # 此时近邻列表中d的最大值也就减小了，所以要相应地减小搜索半径。

            if node._is_leaf():  # 若当前结点是叶结点，则继续下一次循环
                continue

            # 再处理待访问结点列表，有四种情况：只插入该结点的左子树；只插入该结点的右子树；左右子树都插入，左右子树都不插入
            # 下面的两个if模块对应于这四种情况，分别判断是否插入左子树，右子树。
            # 首先判断是否插入该结点的左子树，这里蓝圈中由left_min和left_max围成的环表示当前结点的左子树
            # 第一种情况，查询点位于蓝圈的环内：红圈必与蓝圈有交集，因此需要检查当前结点的左子树，这里insert是插入列表头部，append是插入列表尾部
            if node.left_min <= d <= node.left_max:
                nodes_to_visit.insert(0, (node.left, 0))
            # 第二种情况，查询点虽然不在蓝圈的环内，但是红圈与蓝圈的环有交集，因此需要检查左子树。
            # 两个极端情况分别是红圈与环的内圆外切，红圈与环的外圆外切。
            elif node.left_min - furthest_d <= d <= node.left_max + furthest_d:
                nodes_to_visit.append((node.left,
                                       node.left_min - d if d < node.left_min
                                       else d - node.left_max))
            # 上述两个if如果都没有执行，就表明查询点不在蓝圈的环内，而且红圈与蓝圈的环没有交集，也就是当前结点的左子树中
            # 没有任何结点位于红圈内，因此无需插入左子树。

            # 判断是否插入该结点的右子树，这里蓝圈外由right_min和right_max围成的环表示结点的右子树
            # 第一种情况，查询点位于蓝圈的环内：红圈必与蓝圈有交集，因此需要检查当前结点的右子树
            if node.right_min <= d <= node.right_max:
                nodes_to_visit.insert(0, (node.right, 0))
            # 第二种情况，查询点虽然不在蓝圈的环内，但是红圈与蓝圈的环有交集，因此需要检查右子树。
            # 两个极端情况分别是红圈与环的内圆外切，红圈与环的外圆外切。
            elif node.right_min - furthest_d <= d <= node.right_max + furthest_d:
                nodes_to_visit.append((node.right,
                                       node.right_min - d if d < node.right_min
                                       else d - node.right_max))

            # 上述两个if如果都没有执行，就表明查询点不在蓝圈的环内，而且红圈与蓝圈的环没有交集，也就是当前结点的右子树中
            # 没有任何结点位于红圈内，因此无需插入右子树。
        return list(neighbors)

    def get_all_in_range(self, query, max_distance):  # 返回最大距离之内的所有近邻
        """ Find all neighbours within `max_distance`.

        Parameters
        ----------
        query : Any
            Query point.
        max_distance : float
            Threshold distance for query.

        Returns
        -------
        neighbors : list
            List of points within `max_distance`.

        Notes
        -----
        Returned neighbors are not sorted according to distance.
        """
        neighbors = list()
        nodes_to_visit = [(self, 0)]

        while len(nodes_to_visit) > 0:
            node, d0 = nodes_to_visit.pop(0)
            if node is None or d0 > max_distance:
                continue

            d = self.dist_fn(query, node.vp)
            if d < max_distance:
                neighbors.append((d, node.vp))

            if node._is_leaf():
                continue

            if node.left_min <= d <= node.left_max:
                nodes_to_visit.insert(0, (node.left, 0))
            elif node.left_min - max_distance <= d <= node.left_max + max_distance:
                nodes_to_visit.append((node.left,
                                       node.left_min - d if d < node.left_min
                                       else d - node.left_max))

            if node.right_min <= d <= node.right_max:
                nodes_to_visit.insert(0, (node.right, 0))
            elif node.right_min - max_distance <= d <= node.right_max + max_distance:
                nodes_to_visit.append((node.right,
                                       node.right_min - d if d < node.right_min
                                       else d - node.right_max))

        return neighbors


class _AutoSortingList(list):

    """ Simple auto-sorting list.

    Inefficient for large sizes since the queue is sorted at
    each push.

    Parameters
    ---------
    size : int, optional
        Max queue size.
    """

    def __init__(self, max_size=None, *args):
        super(_AutoSortingList, self).__init__(*args)
        self.max_size = max_size

    def append(self, item):
        """ Append `item` and sort.

        Parameters
        ----------
        item : Any
            Input item.
        """
        super(_AutoSortingList, self).append(item)
        self.sort()
        if self.max_size is not None and len(self) > self.max_size:
            self.pop()

