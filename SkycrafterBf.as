Polyhedron g_finishPoly;
Polyhedron g_roadCheckpointPoly;
Polyhedron g_roadCheckpointUpPoly;
Polyhedron g_roadCheckpointDownPoly;
Polyhedron g_roadCheckpointLeftPoly;
Polyhedron g_roadCheckpointRightPoly;
Polyhedron g_platformCheckpointPoly;
Polyhedron g_platformCheckpointUpPoly;
Polyhedron g_platformCheckpointDownPoly;
Polyhedron g_platformCheckpointLeftPoly;
Polyhedron g_platformCheckpointRightPoly;
Polyhedron g_roadDirtHighCheckpointPoly;
Polyhedron g_roadDirtCheckpointPoly;
Polyhedron g_grassCheckpointPoly;
Polyhedron g_ringHCheckpointPoly;
Polyhedron g_ringVCheckpointPoly;
dictionary g_triggerPolyhedrons;
void InitializeTriggerData() {
    g_finishPoly = Polyhedron(
        {vec3(3.0, 1.0, 12.205891), vec3(3.0, 1.0, 11.79281), vec3(30.0, 1.0, 11.79281), vec3(30.0, 1.0, 12.205891), vec3(30.0, 1.9485588, 12.205891), vec3(26.664326, 5.083612, 12.205891), vec3(19.401665, 7.814228, 12.205891), vec3(12.598329, 7.814228, 12.205891), vec3(5.325968, 5.0799665, 12.205891), vec3(3.0, 2.889081, 12.205891), vec3(30.0, 1.9485588, 11.79281), vec3(3.0, 2.889081, 11.792811), vec3(5.325968, 5.0799665, 11.79281), vec3(12.598328, 7.814228, 11.79281), vec3(19.401665, 7.814228, 11.79281), vec3(26.664326, 5.083612, 11.79281)},
        {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
    );
    g_roadCheckpointPoly = Polyhedron(
        {vec3(3.0, 1.0, 16.20654), vec3(3.0, 1.0, 15.793459), vec3(30.0, 1.0, 15.793459), vec3(30.0, 1.0, 16.20654), vec3(30.0, 1.9485588, 16.20654), vec3(26.664326, 5.083612, 16.20654), vec3(19.401665, 7.814228, 16.20654), vec3(12.598328, 7.814228, 16.20654), vec3(5.325968, 5.0799665, 16.20654), vec3(3.0, 2.8890808, 16.20654), vec3(30.0, 1.9485588, 15.793459), vec3(3.0, 2.8890808, 15.793459), vec3(5.325968, 5.0799665, 15.793459), vec3(12.598328, 7.814228, 15.793459), vec3(19.401665, 7.814228, 15.793459), vec3(26.664326, 5.083612, 15.793459)},
        {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
    );
    g_roadCheckpointUpPoly = Polyhedron(
        {vec3(3.0, 5.305454, 16.20654), vec3(3.0, 5.205257, 15.79346), vec3(30.0, 5.205257, 15.793459), vec3(30.0, 5.305454, 16.20654), vec3(30.0, 6.0024333, 16.20654), vec3(26.664326, 9.137486, 16.20654), vec3(19.401665, 11.868102, 16.20654), vec3(12.598328, 11.868102, 16.20654), vec3(5.325968, 9.133841, 16.20654), vec3(3.0, 6.942955, 16.20654), vec3(30.0, 5.9022365, 15.793459), vec3(3.0, 6.842759, 15.79346), vec3(5.325968, 9.033645, 15.79346), vec3(12.598328, 11.767906, 15.79346), vec3(19.401665, 11.767906, 15.793459), vec3(26.664326, 9.03729, 15.793459)},
        {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
    );
    g_roadCheckpointDownPoly = Polyhedron(
        {vec3(29.133787, 5.305454, 15.793457), vec3(29.133787, 5.205257, 16.206537), vec3(2.1337872, 5.205257, 16.206541), vec3(2.1337872, 5.305454, 15.793461), vec3(2.1337872, 6.0024333, 15.793461), vec3(5.4694614, 9.137486, 15.793461), vec3(12.732122, 11.868102, 15.793459), vec3(19.53546, 11.868102, 15.793458), vec3(26.80782, 9.133841, 15.793457), vec3(29.133787, 6.942955, 15.793457), vec3(2.1337872, 5.9022365, 16.206541), vec3(29.133787, 6.842759, 16.206537), vec3(26.80782, 9.033645, 16.206537), vec3(19.53546, 11.767906, 16.206537), vec3(12.732122, 11.767906, 16.20654), vec3(5.4694605, 9.03729, 16.206541)},
        {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
    );
    g_roadCheckpointLeftPoly = Polyhedron(
        {vec3(3.0, 8.565392, 16.20654), vec3(3.0, 8.565392, 15.793459), vec3(30.0, 1.7613418, 15.793459), vec3(30.0, 1.7613418, 16.20654), vec3(30.0, 2.7099004, 16.20654), vec3(26.664326, 6.6855497, 16.20654), vec3(19.401665, 11.24637, 16.20654), vec3(12.598328, 12.960824, 16.20654), vec3(5.325968, 12.05921, 16.20654), vec3(3.0, 10.454473, 16.20654), vec3(30.0, 2.7099004, 15.793459), vec3(3.0, 10.454473, 15.793459), vec3(5.325968, 12.05921, 15.793459), vec3(12.598328, 12.960824, 15.793459), vec3(19.401665, 11.24637, 15.793459), vec3(26.664326, 6.6855497, 15.793459)},
        {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
    );
    g_roadCheckpointRightPoly = Polyhedron(
        {vec3(29.0, 8.512752, 16.20654), vec3(2.0, 1.7087021, 16.20654), vec3(2.0, 1.7087021, 15.793459), vec3(29.0, 8.512752, 15.793458), vec3(26.674032, 12.00657, 16.206537), vec3(19.401672, 12.908184, 16.206537), vec3(12.598335, 11.19373, 16.206537), vec3(29.0, 10.401833, 16.20654), vec3(5.3356743, 6.6329103, 16.20654), vec3(2.0, 2.657261, 16.20654), vec3(2.0, 2.657261, 15.793459), vec3(5.3356743, 6.6329103, 15.793458), vec3(12.598335, 11.19373, 15.793458), vec3(19.401672, 12.908184, 15.793458), vec3(26.674032, 12.00657, 15.793458), vec3(29.0, 10.401833, 15.793458)},
        {{0,1,2}, {2,3,0}, {4,5,6}, {7,4,6}, {6,8,9}, {6,9,1}, {7,6,1}, {0,7,1}, {2,1,9}, {9,10,2}, {10,11,12}, {12,13,14}, {14,15,3}, {12,14,3}, {10,12,3}, {2,10,3}, {0,3,15}, {15,7,0}, {6,5,13}, {13,12,6}, {8,6,12}, {12,11,8}, {14,13,5}, {5,4,14}, {15,14,4}, {4,7,15}, {9,8,11}, {11,10,9}}
    );
    g_platformCheckpointPoly = Polyhedron(
        {vec3(30.179214, 7.9320526, 16.09842), vec3(28.640587, 9.741932, 16.09842), vec3(26.304703, 11.035336, 16.09842), vec3(22.725918, 12.514831, 16.09842), vec3(18.33589, 13.464806, 16.09842), vec3(13.664118, 13.464806, 16.09842), vec3(9.274088, 12.514832, 16.09842), vec3(5.695303, 11.035337, 16.09842), vec3(3.359416, 9.741935, 16.09842), vec3(1.8207855, 7.9320536, 16.09842), vec3(3.359416, 9.741935, 15.658419), vec3(1.8207855, 7.9320545, 15.658419), vec3(5.695303, 11.035337, 15.658419), vec3(9.274088, 12.514832, 15.658419), vec3(13.664118, 13.464806, 15.658419), vec3(18.33589, 13.464806, 15.658419), vec3(22.725918, 12.51483, 15.658419), vec3(26.304703, 11.035336, 15.658419), vec3(28.640587, 9.741932, 15.658419), vec3(30.179214, 7.9320536, 15.658419)},
        {{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}}
    );
    g_platformCheckpointUpPoly = Polyhedron(
        {vec3(30.179218, 15.981263, 16.09842), vec3(28.64059, 17.791142, 16.09842), vec3(26.304707, 19.084545, 16.09842), vec3(22.725922, 20.56404, 16.09842), vec3(18.33589, 21.514013, 16.098421), vec3(13.664118, 21.514013, 16.098421), vec3(9.274088, 20.564041, 16.098421), vec3(5.695304, 19.084547, 16.09842), vec3(3.359417, 17.791147, 16.09842), vec3(1.8207862, 15.981263, 16.09842), vec3(3.3594167, 17.571144, 15.658419), vec3(1.8207862, 15.761264, 15.658419), vec3(5.695303, 18.864546, 15.658415), vec3(9.274088, 20.34404, 15.658419), vec3(13.664118, 21.294012, 15.658419), vec3(18.33589, 21.294014, 15.658419), vec3(22.725918, 20.344038, 15.658417), vec3(26.304703, 18.864544, 15.658417), vec3(28.640587, 17.571142, 15.658417), vec3(30.179214, 15.761261, 15.658419)},
        {{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}}
    );
    g_platformCheckpointDownPoly = Polyhedron(
        {vec3(30.179218, 15.882843, 16.09842), vec3(28.64059, 17.692722, 16.09842), vec3(26.304707, 18.986124, 16.09842), vec3(22.725922, 20.465622, 16.09842), vec3(18.33589, 21.415592, 16.098421), vec3(13.664118, 21.415594, 16.098421), vec3(9.274087, 20.465622, 16.098421), vec3(5.6953034, 18.986126, 16.09842), vec3(3.3594165, 17.692722, 16.09842), vec3(1.8207858, 15.882844, 16.09842), vec3(3.3594162, 17.912724, 15.658421), vec3(1.8207858, 16.102846, 15.658419), vec3(5.695303, 19.206125, 15.658421), vec3(9.274087, 20.68562, 15.658421), vec3(13.664118, 21.635593, 15.658421), vec3(18.33589, 21.635593, 15.658421), vec3(22.725918, 20.68562, 15.658421), vec3(26.304703, 19.206125, 15.658421), vec3(28.640587, 17.912722, 15.658421), vec3(30.179214, 16.102844, 15.658422)},
        {{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}}
    );
    g_platformCheckpointLeftPoly = Polyhedron(
        {vec3(30.179218, 8.842444, 16.09842), vec3(28.64059, 11.421638, 16.09842), vec3(26.304707, 13.882984, 16.09842), vec3(22.725922, 17.15187, 16.09842), vec3(18.33589, 20.29686, 16.098423), vec3(13.664118, 22.632746, 16.098423), vec3(9.274087, 23.877789, 16.098421), vec3(5.6953034, 24.187687, 16.098421), vec3(3.3594165, 24.062225, 16.09842), vec3(1.8207858, 23.02166, 16.09842), vec3(3.3594162, 24.062225, 15.658421), vec3(1.8207858, 23.021664, 15.658422), vec3(5.695303, 24.187685, 15.658421), vec3(9.274087, 23.877785, 15.658422), vec3(13.664118, 22.632746, 15.658422), vec3(18.33589, 20.29686, 15.658422), vec3(22.725918, 17.151869, 15.658421), vec3(26.304703, 13.882983, 15.658421), vec3(28.640587, 11.421638, 15.658421), vec3(30.179214, 8.842445, 15.658422)},
        {{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}}
    );
    g_platformCheckpointRightPoly = Polyhedron(
        {vec3(30.179218, 23.02166, 16.09842), vec3(28.64059, 24.062227, 16.09842), vec3(26.304707, 24.187685, 16.09842), vec3(22.725922, 23.877789, 16.09842), vec3(18.33589, 22.632751, 16.098421), vec3(13.664118, 20.296865, 16.098421), vec3(9.274087, 17.151875, 16.098421), vec3(5.6953034, 13.882988, 16.09842), vec3(3.3594165, 11.421643, 16.09842), vec3(1.8207858, 8.842446, 16.09842), vec3(3.3594162, 11.421643, 15.658421), vec3(1.8207858, 8.842446, 15.658419), vec3(5.695303, 13.882988, 15.658421), vec3(9.274087, 17.151875, 15.658421), vec3(13.664118, 20.296864, 15.658421), vec3(18.33589, 22.63275, 15.658421), vec3(22.725918, 23.877785, 15.658421), vec3(26.304703, 24.187685, 15.658421), vec3(28.640587, 24.062225, 15.658421), vec3(30.179214, 23.02166, 15.658422)},
        {{0,1,2}, {2,3,4}, {4,5,6}, {6,7,8}, {4,6,8}, {2,4,8}, {0,2,8}, {9,0,8}, {9,8,10}, {10,11,9}, {8,7,12}, {12,10,8}, {7,6,13}, {13,12,7}, {6,5,14}, {14,13,6}, {5,4,15}, {15,14,5}, {4,3,16}, {16,15,4}, {3,2,17}, {17,16,3}, {2,1,18}, {18,17,2}, {1,0,19}, {19,18,1}, {11,19,0}, {9,11,0}, {10,12,13}, {13,14,15}, {15,16,17}, {17,18,19}, {15,17,19}, {13,15,19}, {10,13,19}, {11,10,19}}
    );
    g_roadDirtHighCheckpointPoly = Polyhedron(
        {vec3(3.7928343, -0.09202623, 16.20654), vec3(3.7928343, -0.09202623, 15.793459), vec3(28.268883, -0.09202623, 15.793459), vec3(28.268883, -0.09202623, 16.20654), vec3(28.268883, 1.1523709, 16.20654), vec3(25.85778, 3.959106, 16.20654), vec3(19.401665, 7.2270656, 16.20654), vec3(12.598328, 7.2270656, 16.20654), vec3(6.1362143, 3.8242507, 16.20654), vec3(3.7928343, 1.1458168, 16.20654), vec3(28.268883, 1.1523709, 15.793459), vec3(3.7928343, 1.1458168, 15.793459), vec3(6.1362143, 3.8242507, 15.793459), vec3(12.598328, 7.2270656, 15.793459), vec3(19.401665, 7.2270656, 15.793459), vec3(25.85778, 3.959106, 15.793459)},
        {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
    );
    g_roadDirtCheckpointPoly = Polyhedron(
        {vec3(2.063568, -1.1490858, 16.20654), vec3(2.063568, -1.1490858, 15.793459), vec3(30.0, -1.1490858, 15.793459), vec3(30.0, -1.1490858, 16.20654), vec3(30.0, 3.4846723, 16.20654), vec3(26.664326, 6.291407, 16.20654), vec3(19.401665, 8.890814, 16.20654), vec3(12.598328, 8.890814, 16.20654), vec3(5.325968, 6.156552, 16.20654), vec3(2.063568, 3.478118, 16.20654), vec3(30.0, 3.4846723, 15.793459), vec3(2.063568, 3.478118, 15.793459), vec3(5.325968, 6.156552, 15.793459), vec3(12.598328, 8.890814, 15.793459), vec3(19.401665, 8.890814, 15.793459), vec3(26.664326, 6.291407, 15.793459)},
        {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
    );
    g_grassCheckpointPoly = Polyhedron(
        {vec3(3.0, -0.32810664, 16.20654), vec3(3.0, -0.32810664, 15.793459), vec3(29.103638, -0.32810664, 15.793459), vec3(29.103638, -0.32810664, 16.20654), vec3(30.0, 1.9485588, 16.20654), vec3(26.664326, 5.083612, 16.20654), vec3(19.401665, 7.814228, 16.20654), vec3(12.598328, 7.814228, 16.20654), vec3(5.325968, 5.0799665, 16.20654), vec3(2.2881927, 1.4034786, 16.20654), vec3(30.0, 1.9485588, 15.793459), vec3(2.2881927, 1.4034786, 15.793459), vec3(5.325968, 5.0799665, 15.793459), vec3(12.598328, 7.814228, 15.793459), vec3(19.401665, 7.814228, 15.793459), vec3(26.664326, 5.083612, 15.793459)},
        {{0,1,2}, {2,3,0}, {4,5,6}, {3,4,6}, {6,7,8}, {6,8,9}, {3,6,9}, {0,3,9}, {2,10,4}, {4,3,2}, {1,11,12}, {12,13,14}, {1,12,14}, {14,15,10}, {1,14,10}, {2,1,10}, {0,9,11}, {11,1,0}, {6,14,13}, {13,7,6}, {5,15,14}, {14,6,5}, {12,8,7}, {7,13,12}, {11,9,8}, {8,12,11}, {4,10,15}, {15,5,4}}
    );
    g_ringHCheckpointPoly = Polyhedron(
        {vec3(26.156471, 3.7799995, 24.192066), vec3(22.629168, 3.7799993, 27.151827), vec3(18.302288, 3.779999, 28.726685), vec3(13.69772, 3.779999, 28.726685), vec3(9.370839, 3.7799993, 27.15183), vec3(5.843534, 3.7799995, 24.192072), vec3(3.541249, 3.7799997, 20.2044), vec3(2.7416735, 3.7800002, 15.669784), vec3(3.5412476, 3.7800007, 11.135169), vec3(5.843531, 3.780001, 7.147495), vec3(9.370835, 3.7800012, 4.187733), vec3(13.697715, 3.7800014, 2.6128778), vec3(18.302284, 3.7800014, 2.6128778), vec3(22.629164, 3.7800012, 4.187733), vec3(26.156467, 3.780001, 7.147493), vec3(28.458754, 3.7800007, 11.135166), vec3(29.258327, 3.7800002, 15.669782), vec3(28.458754, 3.7799997, 20.204391), vec3(28.458754, 4.2200007, 11.135166), vec3(29.258327, 4.2200003, 15.669782), vec3(26.156467, 4.2200007, 7.147493), vec3(22.629164, 4.220001, 4.187733), vec3(18.302284, 4.220001, 2.612878), vec3(13.697715, 4.220001, 2.6128778), vec3(9.370835, 4.220001, 4.187733), vec3(5.843531, 4.2200007, 7.147495), vec3(3.5412476, 4.2200007, 11.135169), vec3(2.7416735, 4.2200003, 15.669784), vec3(3.541249, 4.22, 20.2044), vec3(5.843534, 4.2199993, 24.192074), vec3(9.370839, 4.2199993, 27.151833), vec3(13.69772, 4.219999, 28.726686), vec3(18.302288, 4.219999, 28.726685), vec3(22.629168, 4.2199993, 27.151829), vec3(26.156471, 4.2199993, 24.192068), vec3(28.458754, 4.22, 20.204393)},
        {{0,1,2}, {2,3,4}, {4,5,6}, {2,4,6}, {6,7,8}, {8,9,10}, {6,8,10}, {10,11,12}, {12,13,14}, {10,12,14}, {6,10,14}, {2,6,14}, {14,15,16}, {2,14,16}, {0,2,16}, {17,0,16}, {16,15,18}, {18,19,16}, {15,14,20}, {20,18,15}, {14,13,21}, {21,20,14}, {13,12,22}, {22,21,13}, {12,11,23}, {23,22,12}, {11,10,24}, {24,23,11}, {10,9,25}, {25,24,10}, {9,8,26}, {26,25,9}, {8,7,27}, {27,26,8}, {7,6,28}, {28,27,7}, {6,5,29}, {29,28,6}, {5,4,30}, {30,29,5}, {4,3,31}, {31,30,4}, {3,2,32}, {32,31,3}, {2,1,33}, {33,32,2}, {1,0,34}, {34,33,1}, {0,17,35}, {35,34,0}, {17,16,19}, {19,35,17}, {19,18,20}, {20,21,22}, {22,23,24}, {20,22,24}, {24,25,26}, {26,27,28}, {24,26,28}, {28,29,30}, {30,31,32}, {28,30,32}, {24,28,32}, {20,24,32}, {32,33,34}, {20,32,34}, {19,20,34}, {35,19,34}}
    );
    g_ringVCheckpointPoly = Polyhedron(
        {vec3(26.156471, 24.522285, 16.09842), vec3(22.629168, 27.482046, 16.09842), vec3(18.302288, 29.056904, 16.09842), vec3(13.697719, 29.056904, 16.09842), vec3(9.370839, 27.48205, 16.09842), vec3(5.8435335, 24.522291, 16.09842), vec3(3.5412483, 20.534618, 16.09842), vec3(2.7416725, 16.000002, 16.09842), vec3(3.5412464, 11.465387, 16.09842), vec3(5.8435307, 7.4777126, 16.09842), vec3(9.370834, 4.517952, 16.09842), vec3(13.697714, 2.9430962, 16.09842), vec3(18.302284, 2.9430962, 16.09842), vec3(22.629164, 4.517951, 16.09842), vec3(26.156467, 7.4777107, 16.09842), vec3(28.458752, 11.4653845, 16.09842), vec3(29.258327, 16.0, 16.09842), vec3(28.458754, 20.53461, 16.09842), vec3(28.458752, 11.4653845, 15.658419), vec3(29.258327, 16.0, 15.658419), vec3(26.156467, 7.4777107, 15.658419), vec3(22.629164, 4.517951, 15.658419), vec3(18.302284, 2.9430962, 15.658419), vec3(13.697714, 2.9430962, 15.658419), vec3(9.370834, 4.517952, 15.658419), vec3(5.8435307, 7.4777126, 15.658419), vec3(3.5412464, 11.465387, 15.658419), vec3(2.7416725, 16.000002, 15.658419), vec3(3.5412483, 20.534618, 15.65842), vec3(5.8435335, 24.522291, 15.65842), vec3(9.370839, 27.48205, 15.65842), vec3(13.697719, 29.056904, 15.65842), vec3(18.302288, 29.056904, 15.65842), vec3(22.629168, 27.482046, 15.65842), vec3(26.156471, 24.522285, 15.65842), vec3(28.458754, 20.53461, 15.65842)},
        {{0,1,2}, {2,3,4}, {4,5,6}, {2,4,6}, {6,7,8}, {8,9,10}, {6,8,10}, {10,11,12}, {12,13,14}, {10,12,14}, {6,10,14}, {2,6,14}, {14,15,16}, {2,14,16}, {0,2,16}, {17,0,16}, {16,15,18}, {18,19,16}, {15,14,20}, {20,18,15}, {14,13,21}, {21,20,14}, {13,12,22}, {22,21,13}, {12,11,23}, {23,22,12}, {11,10,24}, {24,23,11}, {10,9,25}, {25,24,10}, {9,8,26}, {26,25,9}, {8,7,27}, {27,26,8}, {7,6,28}, {28,27,7}, {6,5,29}, {29,28,6}, {5,4,30}, {30,29,5}, {4,3,31}, {31,30,4}, {3,2,32}, {32,31,3}, {2,1,33}, {33,32,2}, {1,0,34}, {34,33,1}, {0,17,35}, {35,34,0}, {17,16,19}, {19,35,17}, {19,18,20}, {20,21,22}, {22,23,24}, {20,22,24}, {24,25,26}, {26,27,28}, {24,26,28}, {28,29,30}, {30,31,32}, {28,30,32}, {24,28,32}, {20,24,32}, {32,33,34}, {20,32,34}, {19,20,34}, {35,19,34}}
    );
    g_triggerPolyhedrons["StadiumRoadMainCheckpoint"] = @g_roadCheckpointPoly;
    g_triggerPolyhedrons["StadiumGrassCheckpoint"] = @g_grassCheckpointPoly;
    g_triggerPolyhedrons["StadiumRoadMainCheckpointUp"] = @g_roadCheckpointUpPoly;
    g_triggerPolyhedrons["StadiumRoadMainCheckpointDown"] = @g_roadCheckpointDownPoly;
    g_triggerPolyhedrons["StadiumRoadMainCheckpointLeft"] = @g_roadCheckpointLeftPoly;
    g_triggerPolyhedrons["StadiumRoadMainCheckpointRight"] = @g_roadCheckpointRightPoly;
    g_triggerPolyhedrons["StadiumCheckpointRingV"] = @g_ringVCheckpointPoly;
    g_triggerPolyhedrons["StadiumCheckpointRingHRoad"] = @g_ringHCheckpointPoly;
    g_triggerPolyhedrons["StadiumPlatformCheckpoint"] = @g_platformCheckpointPoly;
    g_triggerPolyhedrons["StadiumPlatformCheckpointUp"] = @g_platformCheckpointUpPoly;
    g_triggerPolyhedrons["StadiumPlatformCheckpointDown"] = @g_platformCheckpointDownPoly;
    g_triggerPolyhedrons["StadiumPlatformCheckpointLeft"] = @g_platformCheckpointLeftPoly;
    g_triggerPolyhedrons["StadiumPlatformCheckpointRight"] = @g_platformCheckpointRightPoly;
    g_triggerPolyhedrons["StadiumRoadDirtHighCheckpoint"] = @g_roadDirtHighCheckpointPoly;
    g_triggerPolyhedrons["StadiumRoadDirtCheckpoint"] = @g_roadDirtCheckpointPoly;
    g_triggerPolyhedrons["StadiumRoadMainFinishLine"] = @g_finishPoly;

}
array<Ellipsoid> g_carEllipsoids;
array<Polyhedron@> g_worldCheckpointPolys;
array<AABB> g_worldCheckpointAABBs;
array<string> g_worldCheckpointNames;
array<Polyhedron@> g_worldFinishPolys;
array<AABB> g_worldFinishAABBs;

uint64 g_totalOnEvaluateTime = 0;
uint64 g_totalCalcMinCarDistTime = 0;
uint64 g_totalVertexTransformTime = 0;
uint64 g_totalClosestPointPolyTime = 0;
uint64 g_onEvaluateCallCount = 0;

const string g_pluginPrefix = "dist_bf";
int g_bfTargetType = -1;
int g_bfTargetCpIndex = -1;
float g_bestBfDistance = 1e18f;
string g_cachedChallengeUid = "";
void CacheCheckpointData() {
    TM::GameCtnChallenge@ challenge = GetCurrentChallenge();
    if (challenge is null) {
        print("Error: Could not get current challenge for caching.", Severity::Error);
        g_cachedChallengeUid = "";
        g_worldCheckpointPolys.Clear();
        g_worldCheckpointAABBs.Clear();
        g_worldCheckpointNames.Clear();
        return;
    }
    if (challenge.Uid == g_cachedChallengeUid) {
        return;
    }

    g_cachedChallengeUid = challenge.Uid;
    g_worldCheckpointPolys.Clear();
    g_worldCheckpointAABBs.Clear();
    g_worldCheckpointNames.Clear();
    array<TM::GameCtnBlock@> blocks = challenge.Blocks;
    if (blocks is null) {
         print("Error: Could not get challenge blocks.", Severity::Error);
         return;
    }

    for (uint i = 0; i < blocks.Length; i++) {
        TM::GameCtnBlock@ block = blocks[i];
        if (block !is null && block.WayPointType == TM::WayPointType::Checkpoint) {
            Polyhedron@ basePoly = Polyhedron();
            if (g_triggerPolyhedrons.Get(block.Name, basePoly)) {
                if (basePoly !is null) {
                    Polyhedron worldPoly = TransformPolyhedronToWorld(basePoly, block);
                    AABB worldAABB = CalculatePolyhedronAABB(worldPoly);
                     g_worldCheckpointPolys.Add(worldPoly);
                     g_worldCheckpointAABBs.Add(worldAABB);
                     g_worldCheckpointNames.Add(block.Name);
                } else {
                     print("Warning: Null polyhedron found in dictionary for block: " + block.Name, Severity::Warning);
                }
            } else {
                print("Warning: No trigger polyhedron defined for checkpoint block: " + block.Name, Severity::Warning);
            }
        }
        else if (block.WayPointType == TM::WayPointType::Finish) {
            Polyhedron@ basePoly = Polyhedron();
            if (g_triggerPolyhedrons.Get(block.Name, basePoly)) {
                if (basePoly !is null) {
                    Polyhedron worldPoly = TransformPolyhedronToWorld(basePoly, block);
                    AABB worldAABB = CalculatePolyhedronAABB(worldPoly);
                    g_worldFinishPolys.Add(worldPoly);
                    g_worldFinishAABBs.Add(worldAABB);
                } else {
                    print("Warning: Null polyhedron found in dictionary for block: " + block.Name, Severity::Warning);
                }
            } else {
                print("Warning: No trigger polyhedron defined for finish block: " + block.Name, Severity::Warning);
            }
        }
    }

}

void RenderBruteforceEvaluationSettingssss() {
    g_bfTargetType = int(GetVariableDouble(g_pluginPrefix + "_target_type"));
    g_bfTargetCpIndex = int(GetVariableDouble(g_pluginPrefix + "_target_cp_index"));
    bool typeChanged = false;
    UI::Text("Optimize for minimum distance to:");
    bool isCpSelected = (g_bfTargetType == 0);
    UI::BeginDisabled(isCpSelected);
    if (UI::Button("Checkpoint Index##TargetBtn")) {
        g_bfTargetType = 0;
        typeChanged = true;
    }
    UI::EndDisabled();
    bool isFinishSelected = (g_bfTargetType == 1);
    UI::BeginDisabled(isFinishSelected);
    if (UI::Button("Finish Line##TargetBtn")) {
        g_bfTargetType = 1;
        typeChanged = true;
    }
    UI::EndDisabled();
    UI::Separator();
    if (g_bfTargetType == 0) {
        UI::Text("Target Checkpoint Settings:");
        UI::Dummy(vec2(0, 5));
        UI::CheckboxVar("Show Checkpoint Numbers", g_pluginPrefix + "_show_cp_numbers");
        UI::PushItemWidth(120);
        UI::InputIntVar("Target Index##CPIndex", g_pluginPrefix + "_target_cp_index", 1);
        UI::PopItemWidth();
        int potentiallyUpdatedIndex = int(GetVariableDouble(g_pluginPrefix + "_target_cp_index"));
        int clampedIndex = Math::Max(0, potentiallyUpdatedIndex);
        if (clampedIndex != g_bfTargetCpIndex || clampedIndex != potentiallyUpdatedIndex) {
             g_bfTargetCpIndex = clampedIndex;
             SetVariable(g_pluginPrefix + "_target_cp_index", g_bfTargetCpIndex);
        } else {
             g_bfTargetCpIndex = clampedIndex;
        }
        string rangeText = "Valid range: 0 to " + (g_worldCheckpointPolys.Length > 0 ? g_worldCheckpointPolys.Length - 1 : 0);
        UI::TextDimmed(rangeText);
        if (g_bfTargetCpIndex >= 0 && g_bfTargetCpIndex < int(g_worldCheckpointNames.Length)) {
             UI::Text("Selected: ");
             UI::SameLine();
             UI::BeginDisabled();
             UI::Text(g_worldCheckpointNames[g_bfTargetCpIndex]);
             UI::EndDisabled();
        } else if (g_worldCheckpointPolys.Length > 0) {
             UI::TextDimmed("Error: Index is out of bounds!");
        } else {
             UI::TextDimmed("No checkpoint data cached.");
        }
    } else {
        UI::Text("Target Finish Settings:");
         UI::Dummy(vec2(0, 5));
        UI::BeginDisabled();
        UI::TextWrapped("The bruteforce will optimize towards the closest point on any finish line block surface.");
        UI::EndDisabled();
    }
    if (typeChanged) {
        SetVariable(g_pluginPrefix + "_target_type", g_bfTargetType);
    }
    UI::Separator();
    string bestDistText = "Current Best Distance Found: ";
    if (g_bestBfDistance > 1e17f) {
        bestDistText += "N/A";
    } else {
         bestDistText += Text::FormatFloat(g_bestBfDistance, "", 0, 4) + " m";
    }
    UI::Text(bestDistText);
    UI::Dummy(vec2(0, 5));
    UI::Text("From");
    UI::SameLine();
    UI::Dummy(vec2(30, 0));
    UI::SameLine();
    UI::PushItemWidth(150);
    UI::InputTimeVar("##Nothing1", g_pluginPrefix + "_bf_time_from");
    UI::PopItemWidth();
    UI::Text("To");
    UI::SameLine();
    UI::Dummy(vec2(49, 0));
    UI::SameLine();
    UI::PushItemWidth(150);
    UI::InputTimeVar("##Nothing2", g_pluginPrefix + "_bf_time_to");
    UI::PopItemWidth();
    UI::Text("Trigger constraint");
    UI::SameLine();
    UI::Dummy(vec2(-11, 0));
    UI::SameLine();
    UI::PushItemWidth(110);
    int triggerId=UI::InputIntVar("##Nothing3", g_pluginPrefix + "_constraint_trigger_index", 1);
    UI::PopItemWidth();
    UI::TextDimmed("0 to disable, 1 or more for the trigger index (see Triggers tab)");
    if (triggerId < 0) {
        triggerId = 0;
        SetVariable(g_pluginPrefix + "_constraint_trigger_index", triggerId);
    }
}
vec3 ProjectPointOnPlane(const vec3&in point, const vec3&in planeNormal, const vec3&in planePoint) {
    float distance = Math::Dot(point - planePoint, planeNormal);
    return point - planeNormal * distance;
}
float PointToSegmentDistanceSq(const vec3&in p, const vec3&in a, const vec3&in b, vec3&out projection) {
    vec3 ab = b - a;
    vec3 ap = p - a;
    float abLenSq = Math::Dot(ab, ab);
    if (abLenSq < 1e-6f) {
        projection = a;
        return DistanceSq(p, a);
    }
    float t = Math::Dot(ap, ab) / abLenSq;
    t = Math::Clamp(t, 0.0f, 1.0f);
    projection = a + ab * t;
    return DistanceSq(p, projection);
}
float DistanceSq(const vec3&in p1, const vec3&in p2) {
    vec3 diff = p1 - p2;
    return Math::Dot(diff, diff);
}

bool IsPointInsideTriangle(const vec3&in point, const vec3&in v0, const vec3&in v1, const vec3&in v2, const vec3&in planeNormal) {
    vec3 edge0 = v1 - v0;
    vec3 edge1 = v2 - v1;
    vec3 edge2 = v0 - v2;
    vec3 p0 = point - v0;
    vec3 p1 = point - v1;
    vec3 p2 = point - v2;
    vec3 edgePlaneNormal0 = Cross(edge0, planeNormal);
    if (Math::Dot(p0, edgePlaneNormal0) > 1e-6f) return false;
    vec3 edgePlaneNormal1 = Cross(edge1, planeNormal);
    if (Math::Dot(p1, edgePlaneNormal1) > 1e-6f) return false;
    vec3 edgePlaneNormal2 = Cross(edge2, planeNormal);
    if (Math::Dot(p2, edgePlaneNormal2) > 1e-6f) return false;
    return true;
}
AABB CalculatePolyhedronAABB(const Polyhedron&in poly) {
    AABB box;
    if (poly.vertices.Length == 0) return box;
    for (uint i = 0; i < poly.vertices.Length; ++i) {
        box.Add(poly.vertices[i]);
    }
    return box;
}
Polyhedron CreateAABBPolyhedron(const vec3&in center, const vec3&in size) {
    vec3 halfSize = size * 0.5f;
    vec3 min = center - halfSize;
    vec3 max = center + halfSize;
    array<vec3> vertices = {
        vec3(min.x, min.y, min.z),
        vec3(max.x, min.y, min.z),
        vec3(max.x, max.y, min.z),
        vec3(min.x, max.y, min.z),
        vec3(min.x, min.y, max.z),
        vec3(max.x, min.y, max.z),
        vec3(max.x, max.y, max.z),
        vec3(min.x, max.y, max.z)
    };
    array<array<int>> faces = {
        {0, 3, 2, 1},
        {4, 5, 6, 7},
        {0, 1, 5, 4},
        {0, 4, 7, 3},
        {1, 2, 6, 5},
        {0, 1, 2, 3},
        {4, 5, 6, 7},
        {0, 1, 5, 4},
        {3, 7, 6, 2}
    };
     faces = {
        {0, 3, 2, 1},
        {4, 5, 6, 7},
        {0, 4, 7, 3},
        {1, 2, 6, 5},
        {0, 1, 5, 4},
        {3, 7, 6, 2}
     };
    return Polyhedron(vertices, faces);
}
Polyhedron TransformPolyhedronToWorld(const Polyhedron&in basePoly, const TM::GameCtnBlock@ block) {
    Polyhedron worldPoly;
    worldPoly.faces = basePoly.faces;
    worldPoly.vertices.Resize(basePoly.vertices.Length);
    vec3 blockOriginWorld = vec3(block.Coord.x * 32.0f, block.Coord.y * 8.0f, block.Coord.z * 32.0f);
    GmVec3 centerOffsetLocal = GmVec3(16.0f, 4.0f, 16.0f);
    GmVec3 blockCenterWorld = GmVec3(blockOriginWorld) + centerOffsetLocal;
    GmMat3 blockRotationMat;
    float angleRad = 0.0f;
    if (block.Dir == TM::CardinalDir::East) {
        angleRad = Math::ToRad(-90.0f);
    } else if (block.Dir == TM::CardinalDir::South) {
        angleRad = Math::ToRad(180.0f);
    } else if (block.Dir == TM::CardinalDir::West) {
        angleRad = Math::ToRad(90.0f);
    }
    if (angleRad != 0.0f) {
        blockRotationMat.RotateY(angleRad);
    }
    for (uint i = 0; i < basePoly.vertices.Length; ++i) {
        GmVec3 baseVertexLocal = GmVec3(basePoly.vertices[i]);
        GmVec3 vertexRelativeToCenterLocal = baseVertexLocal - centerOffsetLocal;
        GmVec3 rotatedRelativeVertex = blockRotationMat.Transform(vertexRelativeToCenterLocal);
        GmVec3 finalWorldVertex = rotatedRelativeVertex + blockCenterWorld;
        worldPoly.vertices[i] = finalWorldVertex.ToVec3();
    }
    return worldPoly;
}

float g_currentWindowMinDistance = 1e18f;
bool g_windowResultProcessed = false;
int g_lastProcessedRaceTime = -1;
int bfTimeFrom = 0;
int bfTimeTo = 0;
AABB triggerIdToAABB(int id) {
    int index = id-1;
    if (index<0){
        return AABB(vec3(-1e18f, -1e18f, -1e18f), vec3(1e18f, 1e18f, 1e18f));
    }
    array<int> triggerIds = GetTriggerIds();
    bool canExist = index <= int(triggerIds.Length);
    if(!canExist){
        print("BF Evaluate: Trigger index " + index + " not found.", Severity::Error);
        return AABB(vec3(1e18f, 1e18f, 1e18f), vec3(-1e18f, -1e18f, -1e18f));
    }
    Trigger3D trigger = GetTriggerByIndex(index);
    return AABB(trigger.Position, trigger.Position + trigger.Size);;
}
Polyhedron g_targetCpPoly;
AABB g_targetCpAABB;
bool g_bfConfigIsValid = false;
string g_bfTargetDescription = "Invalid Target";

Polyhedron g_clippedtargetCpPoly;
AABB@ g_clippedtargetCpAABB;
array<Polyhedron@> g_worldClippedFinishPolys;
array<AABB> g_worldClippedFinishAABBs;

void OnSimulationBegin(SimulationManager@ simManager) {
    if(!(GetVariableString("bf_target")==g_bruteforceDistanceTargetIdentifier && GetVariableString("controller")=="bruteforce")){
        g_bfConfigIsValid = false;
        return;
    }
    g_isNewBFEvaluationRun=true;
    g_simEndProcessed = false;
    g_isEarlyStop=false;

    TM::GameCtnChallenge@ challenge = GetCurrentChallenge();
    if (challenge !is null && challenge.Uid != g_cachedChallengeUid) {
        CacheCheckpointData();
    }
    g_bfConfigIsValid = false;
    bfTimeFrom = int(GetVariableDouble(g_pluginPrefix + "_bf_time_from"));
    bfTimeTo = int(GetVariableDouble(g_pluginPrefix + "_bf_time_to"));
    g_bfTargetType = int(GetVariableDouble(g_pluginPrefix + "_target_type"));

    if (g_bfTargetType == 0) {
        g_bfTargetCpIndex = int(GetVariableDouble(g_pluginPrefix + "_target_cp_index"));
        if (g_bfTargetCpIndex < 0 || g_bfTargetCpIndex >= int(g_worldCheckpointPolys.Length)) {
            print("BF Init Error: Target CP index " + g_bfTargetCpIndex + " is out of bounds (0-" + (g_worldCheckpointPolys.Length) + ").", Severity::Error);
        } else {
            g_targetCpPoly = g_worldCheckpointPolys[g_bfTargetCpIndex];
            if (g_targetCpPoly is null) {
                print("BF Init Error: Target CP polyhedron at index " + g_bfTargetCpIndex + " is null.", Severity::Error);
            } else {
                g_targetCpAABB = g_worldCheckpointAABBs[g_bfTargetCpIndex];
                g_bfTargetDescription = "CP Index " + g_bfTargetCpIndex;
                 if (g_bfTargetCpIndex >= 0 && g_bfTargetCpIndex < int(g_worldCheckpointNames.Length)) {
                     g_bfTargetDescription += " (" + g_worldCheckpointNames[g_bfTargetCpIndex] + ")";
                 }
                g_bfConfigIsValid = true;
            }
        }
    } else if (g_bfTargetType == 1) {
        if (g_worldFinishPolys.IsEmpty()) {
            print("BF Init Error: No finish blocks cached for this map. Cannot evaluate distance.", Severity::Error);
        } else {
             g_bfTargetDescription = "Finish Line";
             if (g_worldFinishPolys.Length > 1) {
                 g_bfTargetDescription += " (Closest of " + g_worldFinishPolys.Length + ")";
             }
            g_bfConfigIsValid = true;
        }
    } else {
        print("BF Init Error: Invalid target type specified: " + g_bfTargetType, Severity::Error);
    }

    if (g_bfConfigIsValid) {

        g_bestBfDistance = 1e18f;
        g_currentWindowMinDistance = 1e18f;
        g_windowResultProcessed = true;
        g_lastProcessedRaceTime = -1;

        g_totalOnEvaluateTime = 0;
        g_totalCalcMinCarDistTime = 0;
        g_totalVertexTransformTime = 0;
        g_totalClosestPointPolyTime = 0;
        g_onEvaluateCallCount = 0;

        AABB triggerAABB = triggerIdToAABB(int(GetVariableDouble(g_pluginPrefix + "_constraint_trigger_index")));
        if (g_bfTargetType == 0) {
            g_clippedtargetCpPoly = ClipPolyhedronByAABB(g_targetCpPoly, triggerAABB);
            g_targetCpAABB = triggerAABB;
        } else if (g_bfTargetType == 1) {
            g_worldClippedFinishPolys.Resize(0);
            g_worldClippedFinishAABBs.Resize(0);
            for (uint i = 0; i < g_worldFinishPolys.Length; ++i) {
                const Polyhedron@ targetPoly = g_worldFinishPolys[i];
                if (targetPoly is null) continue;
                const AABB targetAABB = g_worldFinishAABBs[i];
                log("Trigger AABB: " + triggerAABB.ToString());
                Polyhedron clippedPoly = ClipPolyhedronByAABB(targetPoly, triggerAABB);
                g_worldClippedFinishPolys.Add(clippedPoly);
                g_worldClippedFinishAABBs.Add(targetAABB);
            }
        }
    } else {
         print("BF Initialization failed. Evaluation will be stopped.");
    }
}

bool g_simEndProcessed = false;

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result){
    if(GetVariableString("bf_target") != g_bruteforceDistanceTargetIdentifier || GetVariableString("controller") != "bruteforce"){
        return;
    }
    if(!g_simEndProcessed){
        g_simEndProcessed = true;
        if (g_bfConfigIsValid && g_isEarlyStop){
            g_earlyStopCommandList.Save(GetVariableString("bf_result_filename"));
        }

        print("\n--- Bruteforce Performance Report ---");
        if (g_onEvaluateCallCount == 0) {
            print("No evaluations were run.");
            print("-------------------------------------\n");
            return;
        }

        print("Total evaluations: " + g_onEvaluateCallCount);
        print("Total time in OnEvaluate: " + g_totalOnEvaluateTime + " ms");
        float avgOnEvaluate = float(g_totalOnEvaluateTime) / g_onEvaluateCallCount;
        print("  -> Average per evaluation: " + Text::FormatFloat(avgOnEvaluate, "", 0, 4) + " ms");

        if (g_totalOnEvaluateTime > 0) {
            print("\nBreakdown of OnEvaluate time:");
            uint64 totalMeasuredInside = g_totalCalcMinCarDistTime;
            uint64 overhead = g_totalOnEvaluateTime > totalMeasuredInside ? g_totalOnEvaluateTime - totalMeasuredInside : 0;

            print("  - CalculateMinCarDistanceToPoly: " + g_totalCalcMinCarDistTime + " ms (" + Text::FormatFloat(100.0f * g_totalCalcMinCarDistTime / g_totalOnEvaluateTime, "", 0, 1) + "%)");
            print("  - OnEvaluate Overhead: " + overhead + " ms (" + Text::FormatFloat(100.0f * overhead / g_totalOnEvaluateTime, "", 0, 1) + "%)");

            if (g_totalCalcMinCarDistTime > 0) {
                print("\nBreakdown of CalculateMinCarDistanceToPoly time:");
                uint64 totalCalcDistBreakdown = g_totalVertexTransformTime + g_totalClosestPointPolyTime;
                uint64 calcDistOverhead = g_totalCalcMinCarDistTime > totalCalcDistBreakdown ? g_totalCalcMinCarDistTime - totalCalcDistBreakdown : 0;

                print("    - Vertex Transformations: " + g_totalVertexTransformTime + " ms (" + Text::FormatFloat(100.0f * g_totalVertexTransformTime / g_totalCalcMinCarDistTime, "", 0, 1) + "%)");
                print("    - Polygon Closest Point Checks: " + g_totalClosestPointPolyTime + " ms (" + Text::FormatFloat(100.0f * g_totalClosestPointPolyTime / g_totalCalcMinCarDistTime, "", 0, 1) + "%)");
                print("    - Other (internal logic): " + calcDistOverhead + " ms (" + Text::FormatFloat(100.0f * calcDistOverhead / g_totalCalcMinCarDistTime, "", 0, 1) + "%)");
            }
        }

        print("-------------------------------------\n");
    }
}

class BFResultPrinter {

    int COL_ITER     = 10;
    int COL_PHASE    = 12;
    int COL_TARGET   = 30;
    int COL_WINDOW   = 18;
    int COL_DIST     = 18;
    int COL_IMPROVE  = 18;
    int precision = 8;

    bool headerPrinted = false;

    private string PadString(const string &in str, int width, bool alignRight = false) {
        int len = str.Length;
        if (len >= width) {

            return str.Substr(0, width);
        }
        int padding = width - len;
        string padStr = "";
        for (int i = 0; i < padding; ++i) {
            padStr += " ";
        }
        if (alignRight) {
            return padStr + str;
        } else {
            return str + padStr;
        }
    }

    void PrintHeader(const string &in targetDesc, int timeFrom, int timeTo) {
        string title = "Bruteforce Evaluation Results";
        string targetInfo = "Target: " + targetDesc + " | Window: [" + timeFrom + "-" + timeTo + "] ms";

        string header = PadString("Iteration", COL_ITER) + " | " +
                        PadString("Phase", COL_PHASE) + " | " +

                        PadString("Min Distance", COL_DIST, true) + " | " +
                        PadString("Improvement", COL_IMPROVE, true);

        int totalWidth = header.Length;
        string separator = "";
        for (int i = 0; i < totalWidth; ++i) {
            separator += "-";
        }

        print("");
        print(title);
        print(targetInfo);
        print(separator);
        print(header);
        print(separator);
        headerPrinted = true;
    }

    void PrintRow(int iteration, const string &in phase, float distance, float improvement = -1.0f) {

        string iterStr = Text::FormatInt(iteration);
        string phaseStr = phase;
        string distStr = Text::FormatFloat(distance, "", 0, precision) + " m";
        string improveStr = (improvement >= 0.0f) ? (Text::FormatFloat(improvement, "", 0, precision) + " m") : "N/A";

        string row = PadString(iterStr, COL_ITER, true) + " | " +
                     PadString(phaseStr, COL_PHASE) + " | " +

                     PadString(distStr, COL_DIST, true) + " | " +
                     PadString(improveStr, COL_IMPROVE, true);

        print(row);
    }

    void PrintInitialResult(int iteration, const string &in targetDesc, int timeFrom, int timeTo, float distance) {

        if (!headerPrinted) {
            PrintHeader(targetDesc, timeFrom, timeTo);
        }
        PrintRow(iteration, "Initial", distance, -1.0f);
    }

    void PrintImprovedResult(int iteration, float newDistance, float improvement) {

        if (!headerPrinted) {

             print("BFResultPrinter Warning: Header not printed before improved result!", Severity::Warning);

        }
        PrintRow(iteration, "Improvement", newDistance, improvement);
    }

    void PrintTargetAchieved() {
        if (!headerPrinted) {
            print("BFResultPrinter Warning: Header not printed before target achievement!", Severity::Warning);
        }

        array<string> celebration = {
            "|------------------------------------------------------|",
            "|                                                      |",
            "|                   CONGRATULATIONS!                   |",
            "|                                                      |",
            "|   /$$$$$$  /$$   /$$ /$$     /$$ /$$$$$$$  /$$$$$$$$ |",
            "|  /$$__  $$| $$  /$$/|  $$   /$$/| $$__  $$| $$_____/ |",
            "| | $$  \\__/| $$ /$$/  \\  $$ /$$/ | $$  \\ $$| $$       |",
            "| |  $$$$$$ | $$$$$/    \\  $$$$/  | $$$$$$$ | $$$$$    |",
            "|  \\____  $$| $$  $$     \\  $$/   | $$__  $$| $$__/    |",
            "|  /$$  \\ $$| $$\\  $$     | $$    | $$  \\ $$| $$       |",
            "| |  $$$$$$/| $$ \\  $$    | $$    | $$$$$$$/| $$       |",
            "|  \\______/ |__/  \\__/    |__/    |_______/ |__/       |",
            "|                                                      |",
            "|                Mission accomplished!                 |",
            "|                                                      |",
            "|------------------------------------------------------|"
        };

        print("\n");
        for (uint i = 0; i < celebration.Length; ++i) {
            string leftPadding = "     ";
            string text = leftPadding + celebration[i];
            print(text, Severity::Success);
        }
        print("\n");
    }

    void Reset() {
        headerPrinted = false;
    }
}

BFResultPrinter g_bfPrinter;
bool g_isNewBFEvaluationRun = false;
CommandList g_earlyStopCommandList;
bool g_isEarlyStop = false;

void OnCheckpointCountChanged(SimulationManager@ simManager, int current, int target){
    if(GetVariableString("bf_target") != g_bruteforceDistanceTargetIdentifier || GetVariableString("controller") != "bruteforce"){
        return;
    }
    int raceTime = simManager.RaceTime;
    if(raceTime < bfTimeFrom || raceTime >= bfTimeTo){
        return;
    }

}
BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info) {
    uint64 onEvaluateStartTime = Time::get_Now();
    BFEvaluationResponse@ resp = OnEvaluate_Inner(simManager, info);
    g_onEvaluateCallCount++;
    g_totalOnEvaluateTime += (Time::get_Now() - onEvaluateStartTime);
    return resp;
}
BFEvaluationResponse@ OnEvaluate_Inner(SimulationManager@ simManager, const BFEvaluationInfo&in info) {
    auto resp = BFEvaluationResponse();
    resp.Decision = BFEvaluationDecision::DoNothing;
    if (!g_bfConfigIsValid) {
        resp.Decision = BFEvaluationDecision::Stop;
        return resp;
    }

    int raceTime = simManager.RaceTime;

    if (raceTime < g_lastProcessedRaceTime) {
        g_currentWindowMinDistance = 1e18f;
        g_windowResultProcessed = false;
    }
    g_lastProcessedRaceTime = raceTime;

    TM::PlayerInfo@ playerInfo = simManager.PlayerInfo;

    bool isInWindow = (raceTime >= bfTimeFrom && raceTime < bfTimeTo);
    bool isDecisionTime = (raceTime == bfTimeTo);

    bool shouldCalculateDistance = isInWindow || (isDecisionTime && !g_windowResultProcessed);
    float currentTickDistance = 1e18f;

    if (shouldCalculateDistance) {
        g_windowResultProcessed = false;
        GmIso4 carWorldTransform = GmIso4(simManager.Dyna.CurrentState.Location);

        if (g_bfTargetType == 0) {
            const Polyhedron@ targetPoly;
            const AABB targetAABB = g_targetCpAABB;
            int constraintTriggerIndex = int(GetVariableDouble(g_pluginPrefix + "_constraint_trigger_index"));
            bool constraintIsActive = (constraintTriggerIndex > 0);
            if (constraintIsActive) {
                @targetPoly = g_clippedtargetCpPoly;
            } else {
                @targetPoly = g_targetCpPoly;
            }

            bool needsAccurateDistance = targetAABB.Contains(carWorldTransform.m_Position.ToVec3(), 15);
            if (needsAccurateDistance) {
                currentTickDistance = CalculateMinCarDistanceToPoly(carWorldTransform, targetPoly);
            } else {
                currentTickDistance = Math::Max(0.0f, targetAABB.DistanceToPoint(carWorldTransform.m_Position.ToVec3()));
            }
        } else {
            float minDistToAnyFinish = 1e18f;
            for (uint i = 0; i < g_worldClippedFinishPolys.Length; ++i) {
               const Polyhedron@ targetPoly = g_worldClippedFinishPolys[i];
                if (targetPoly is null || targetPoly.faces.Length == 0) continue;
                const AABB targetAABB = g_worldClippedFinishAABBs[i];

                bool needsAccurateDistance = targetAABB.Contains(carWorldTransform.m_Position.ToVec3(), 15);
                float distToThisFinish = 1e18f;
                if (needsAccurateDistance) {
                    distToThisFinish = CalculateMinCarDistanceToPoly(carWorldTransform, targetPoly);
                } else {
                    distToThisFinish = Math::Max(0.0f, targetAABB.DistanceToPoint(carWorldTransform.m_Position.ToVec3()));
                }
                minDistToAnyFinish = Math::Min(minDistToAnyFinish, distToThisFinish);
            }
            currentTickDistance = minDistToAnyFinish;
        }
        g_currentWindowMinDistance = Math::Min(g_currentWindowMinDistance, currentTickDistance);
    }

    if (isDecisionTime && !g_windowResultProcessed) {
        g_windowResultProcessed = true;
        if(g_bfTargetType == 1 && playerInfo.RaceFinished){
            g_isEarlyStop = true;
        }
        if (g_isEarlyStop) {
            g_earlyStopCommandList.Content = simManager.InputEvents.ToCommandsText();
            resp.Decision = BFEvaluationDecision::Stop;
            g_bfPrinter.PrintTargetAchieved();
            return resp;
        }

        float finalMinDistance = g_currentWindowMinDistance;

        if (finalMinDistance == 1e18f) {
             if (shouldCalculateDistance) {
                 finalMinDistance = currentTickDistance;
             } else {
                 print("BF Evaluate: Warning - Could not determine minimum distance at decision time " + raceTime + "ms.", Severity::Warning);
             }
        }

        string targetDesc = g_bfTargetDescription;

        if (info.Phase == BFPhase::Initial) {
            g_bestBfDistance = finalMinDistance;
            resp.Decision = BFEvaluationDecision::Accept;
            if(g_isNewBFEvaluationRun){
                g_bfPrinter.Reset();
                g_isNewBFEvaluationRun = false;
                g_bfPrinter.PrintInitialResult(info.Iterations, targetDesc, bfTimeFrom, bfTimeTo, g_bestBfDistance);

                resp.ResultFileStartContent = "# Baseline min distance to " + targetDesc + " [" + bfTimeFrom + "-" + bfTimeTo + "ms]: " + Text::FormatFloat(g_bestBfDistance, "", 0, 6) + " m";
            }
        } else {
            if (finalMinDistance < g_bestBfDistance) {
                float oldBest = g_bestBfDistance;
                g_bestBfDistance = finalMinDistance;
                resp.Decision = BFEvaluationDecision::Accept;
                g_bfPrinter.PrintImprovedResult(info.Iterations, g_bestBfDistance, oldBest - g_bestBfDistance);

                resp.ResultFileStartContent = "# Found closer state to " + targetDesc + " [" + bfTimeFrom + "-" + bfTimeTo + "ms]: " + Text::FormatFloat(g_bestBfDistance, "", 0, 6) + " m at iteration " + info.Iterations;
            } else {
                resp.Decision = BFEvaluationDecision::Reject;
            }
        }

        g_currentWindowMinDistance = 1e18f;

        return resp;
    }
    return resp;
}
string g_bruteforceDistanceTargetIdentifier = "distance_target";
void Main()
{
    log("Skycrafter Bruteforce Targets v2 loaded.");
    InitializeTriggerData();
    InitializeCarEllipsoids();

    RegisterVariable(g_pluginPrefix + "_target_type", 0);
    RegisterVariable(g_pluginPrefix + "_target_cp_index", 0);
    RegisterVariable(g_pluginPrefix + "_show_cp_numbers", false);
    RegisterVariable(g_pluginPrefix + "_cached_triggers", "");
    RegisterVariable(g_pluginPrefix + "_bf_time_from", 0);
    RegisterVariable(g_pluginPrefix + "_bf_time_to", 0);
    RegisterVariable(g_pluginPrefix + "_constraint_trigger_index", -1);
    RegisterBruteforceEvaluation(
        g_bruteforceDistanceTargetIdentifier,
        "Distance to Target (CP/Finish)",
        OnEvaluate,
        RenderBruteforceEvaluationSettingssss
    );
}
void OnRunStep(SimulationManager@ simManager) {
    int raceTime = simManager.RaceTime;
    if (!simManager.InRace || simManager.RaceTime < 0) {
        return;
    }
    TM::GameCtnChallenge@ challenge = GetCurrentChallenge();
    if (challenge !is null && challenge.Uid != g_cachedChallengeUid) {
        CacheCheckpointData();
        if (challenge.Uid != g_cachedChallengeUid) return;
    }

    float distance = CalculateMinCarDistanceToPoly(
        GmIso4(simManager.Dyna.CurrentState.Location),
        g_worldFinishPolys[0]
    );
    log("Current distance to finish at " + raceTime + "ms: " + Text::FormatFloat(distance, "", 0, 4) + " m");
}
PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Skycrafter Bruteforce Targets";
    info.Author = "Skycrafter";
    info.Version = "2.0.0";
    info.Description = "Bruteforce for skycrafter's targets. Currently available: Distance to CP/Finish.";
    return info;
}

array<array<vec2>> initDigitFont()
{
    array<array<vec2>> digitShapes(10);
    digitShapes[0] = { vec2(0,0), vec2(1,0), vec2(2,0),
                       vec2(0,1),               vec2(2,1),
                       vec2(0,2),               vec2(2,2),
                       vec2(0,3),               vec2(2,3),
                       vec2(0,4), vec2(1,4), vec2(2,4) };
    digitShapes[1] = { vec2(1,0),
                       vec2(1,1),
                       vec2(1,2),
                       vec2(1,3),
                       vec2(1,4) };
    digitShapes[2] = { vec2(0,0), vec2(1,0), vec2(2,0),
                                             vec2(2,1),
                       vec2(0,2), vec2(1,2), vec2(2,2),
                       vec2(0,3),
                       vec2(0,4), vec2(1,4), vec2(2,4) };
    digitShapes[3] = { vec2(0,0), vec2(1,0), vec2(2,0),
                                             vec2(2,1),
                                   vec2(1,2), vec2(2,2),
                                             vec2(2,3),
                       vec2(0,4), vec2(1,4), vec2(2,4) };
    digitShapes[4] = { vec2(0,0),            vec2(2,0),
                       vec2(0,1),            vec2(2,1),
                       vec2(0,2), vec2(1,2), vec2(2,2),
                                             vec2(2,3),
                                             vec2(2,4) };
    digitShapes[5] = { vec2(0,0), vec2(1,0), vec2(2,0),
                       vec2(0,1),
                       vec2(0,2), vec2(1,2), vec2(2,2),
                                             vec2(2,3),
                       vec2(0,4), vec2(1,4), vec2(2,4) };
    digitShapes[6] = { vec2(0,0), vec2(1,0), vec2(2,0),
                       vec2(0,1),
                       vec2(0,2), vec2(1,2), vec2(2,2),
                       vec2(0,3),            vec2(2,3),
                       vec2(0,4), vec2(1,4), vec2(2,4) };
    digitShapes[7] = { vec2(0,0), vec2(1,0), vec2(2,0),
                                             vec2(2,1),
                                             vec2(2,2),
                                             vec2(2,3),
                                             vec2(2,4) };
    digitShapes[8] = { vec2(0,0), vec2(1,0), vec2(2,0),
                       vec2(0,1),            vec2(2,1),
                       vec2(0,2), vec2(1,2), vec2(2,2),
                       vec2(0,3),            vec2(2,3),
                       vec2(0,4), vec2(1,4), vec2(2,4) };
    digitShapes[9] = { vec2(0,0), vec2(1,0), vec2(2,0),
                       vec2(0,1),            vec2(2,1),
                       vec2(0,2), vec2(1,2), vec2(2,2),
                                             vec2(2,3),
                       vec2(0,4), vec2(1,4), vec2(2,4) };
    return digitShapes;
}
array<Trigger3D> GetTextTriggers(const vec3&in camPos, const vec3&in textPos, const string&in text)
{
    array<array<vec2>> digitShapes = initDigitFont();
    float scale = 3.0f;
    float digitSpacing = 2.5f;
    vec3 forward = (camPos - textPos);
    forward = forward / forward.Length();
    vec3 right = Cross(vec3(0, 1, 0), forward);
    right = right / right.Length();
    vec3 up = Cross(forward, right);
    up = up / up.Length();
    float digitWidth  = 3.0f * scale;
    float digitHeight = 5.0f * scale;
    vec2 centerOffset = vec2(digitWidth * 0.5f, digitHeight * 0.5f);
    vec3 currentDigitPos = textPos;
    array<Trigger3D> triggers;
    for(uint i = 0; i < text.Length; i++)
    {
        string c = text.Substr(i, 1);
        if(c < "0" || c > "9")
            continue;
        int digit = Text::ParseInt(c);
        array<vec2> shape = digitShapes[digit];

        for(uint j = 0; j < shape.Length; j++)
        {
            vec2 gridPos = shape[j];

            float offsetX = (gridPos.x * scale) - centerOffset.x;
            float offsetY = (gridPos.y * scale) - centerOffset.y;

            vec3 worldOffset = right * offsetX + up * (-offsetY);

            vec3 cuboidPos = currentDigitPos + worldOffset;

            Trigger3D trig = Trigger3D(cuboidPos, scale);
            triggers.Add(trig);
        }

        currentDigitPos = currentDigitPos + right * (digitWidth + digitSpacing);
    }
    return triggers;
}
void Render()
{
    array<vec3> positions;
    array<string> texts;
    float size = 5;
    for(uint i = 0; i < g_worldCheckpointAABBs.Length; ++i) {
        AABB aabb = g_worldCheckpointAABBs[i];
        vec3 center = aabb.Center();
        positions.Add(center);
        texts.Add(Text::FormatInt(i));
    }
    drawTriggers(positions, size, texts, GetVariableBool(g_pluginPrefix + "_show_cp_numbers"));
}
uint64 last_update=0;
array<vec3> g_textTriggersPositions;
array<string> g_textTriggersTexts;
array<int> g_triggerIds;
vec3 g_textTriggersCamPos;
void drawTriggers(array<vec3> positions, float size, array<string> texts, bool doDraw=true)
{
    TM::GameState gameState = GetCurrentGameState();
    if(gameState == TM::GameState::StartUp){
        return;
    }
    if(positions.Length != texts.Length)
    {
        print("Error: Positions and text arrays must have the same length.");
        return;
    }
    string cachedTriggerIds = GetVariableString(g_pluginPrefix + "_cached_triggers");
    if (g_triggerIds.Length == 0 && cachedTriggerIds != "") {
        array<string> ids = cachedTriggerIds.Split(",");
        for (uint i = 0; i < ids.Length; ++i) {
            g_triggerIds.Add(Text::ParseInt(ids[i]));
        }
        SetVariable(g_pluginPrefix + "_cached_triggers", "");
        print("Loaded " + g_triggerIds.Length + " cached triggers");
    }
    if(!doDraw)
    {
        for (uint i = 0; i < g_triggerIds.Length; ++i) {
            RemoveTrigger(g_triggerIds[i]);
        }
        g_triggerIds.Clear();
        g_textTriggersPositions.Clear();
        g_textTriggersTexts.Clear();
        return;
    }

    if(gameState != TM::GameState::LocalRace) {
        for (uint i = 0; i < g_triggerIds.Length; ++i) {
            RemoveTrigger(g_triggerIds[i]);
        }
        if(g_triggerIds.Length != 0) {
            print("Attempted to remove " + g_triggerIds.Length + " triggers");
        }
        SetVariable(g_pluginPrefix + "_cached_triggers", "");
        g_triggerIds.Clear();
        return;
    }
    uint64 current_time = Time::get_Now();
    if(current_time-last_update>50){
        last_update=Time::get_Now();
        bool different = false || g_textTriggersPositions.Length == 0;
        TM::GameCamera@ camera = GetCurrentCamera();
        SimulationManager@ simManager = GetSimulationManager();
        if(g_textTriggersCamPos != camera.Location.Position) {
            different = true;
            g_textTriggersCamPos = camera.Location.Position;
        }else{
            for(uint i = 0; i < g_textTriggersPositions.Length; ++i) {
                if(g_textTriggersPositions[i] != positions[i] || g_textTriggersTexts[i] != texts[i]) {
                    different = true;
                    break;
                }
            }
        }
        if(different) {
            for (uint i = 0; i < g_triggerIds.Length; ++i) {
                RemoveTrigger(g_triggerIds[i]);
            }
            g_triggerIds.Clear();
            g_textTriggersPositions.Clear();
            g_textTriggersTexts.Clear();
            g_textTriggersPositions = positions;
            g_textTriggersTexts = texts;
            string triggerIds = "";
            for (uint i = 0; i < positions.Length; ++i) {
                array<Trigger3D> triggers = GetTextTriggers(camera.Location.Position, positions[i], texts[i]);
                for (uint j = 0; j < triggers.Length; ++j) {
                    Trigger3D trigger = triggers[j];
                    int triggerId = SetTrigger(trigger);
                    g_triggerIds.Add(triggerId);
                    triggerIds += triggerId + ",";
                }
            }
            triggerIds = triggerIds.Substr(0, triggerIds.Length - 1);
            SetVariable(g_pluginPrefix + "_cached_triggers", triggerIds);
        }
    }
}
vec3 Normalize(vec3 v) {
    float magnitude = v.Length();
    if (magnitude > 1e-6f) {
        return v / magnitude;
    }
    return vec3(0,0,0);
}

vec3 Cross(vec3 a, vec3 b) {
    return vec3(a.y * b.z - a.z * b.y,
                a.z * b.x - a.x * b.z,
                a.x * b.y - a.y * b.x);
}

GmVec3 Cross(const GmVec3&in a, const GmVec3&in b) {
    return GmVec3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    );
}

const float EPSILON = 1e-6f;

GmIso4 GetCarEllipsoidLocationByIndex(SimulationManager@ simM, const GmIso4&in carLocation, uint index) {
    if (index >= 8) {
        print("Error: Invalid ellipsoid index requested: " + index + ". Must be 0-7.", Severity::Error);
        return GmIso4();
    }
     if (index >= 4 && g_carEllipsoids.Length <= index) {
         print("Error: g_carEllipsoids array not initialized correctly for index " + index, Severity::Error);
         return GmIso4();
    }
    auto simManager = GetSimulationManager();
    GmIso4 worldTransform;
    if (index <= 3) {
        GmVec3 wheelSurfaceLocalPos;
        switch(index) {
            case 0: wheelSurfaceLocalPos = GmVec3(simManager.Wheels.FrontLeft.SurfaceHandler.Location.Position); break;
            case 1: wheelSurfaceLocalPos = GmVec3(simManager.Wheels.FrontRight.SurfaceHandler.Location.Position); break;
            case 2: wheelSurfaceLocalPos = GmVec3(simManager.Wheels.BackLeft.SurfaceHandler.Location.Position); break;
            case 3: wheelSurfaceLocalPos = GmVec3(simManager.Wheels.BackRight.SurfaceHandler.Location.Position); break;
            default:
                 print("Error: Unexpected index in wheel section: " + index, Severity::Error);
                 return GmIso4();
        }
        worldTransform.m_Rotation = carLocation.m_Rotation;
        GmVec3 worldSpaceOffset = carLocation.m_Rotation.Transform(wheelSurfaceLocalPos);
        worldTransform.m_Position = carLocation.m_Position + worldSpaceOffset;
    }
    else {
        const GmVec3@ localPositionOffset = g_carEllipsoids[index].center;
        const GmMat3@ localRotation = g_carEllipsoids[index].rotation;
        worldTransform.m_Rotation = carLocation.m_Rotation * localRotation;
        GmVec3 worldSpaceOffset = carLocation.m_Rotation.Transform(localPositionOffset);
        worldTransform.m_Position = carLocation.m_Position + worldSpaceOffset;
    }
    return worldTransform;
}

void InitializeCarEllipsoids() {
    g_carEllipsoids.Clear();
    const array<GmVec3> radii = {
        GmVec3(0.182f, 0.364f, 0.364f),
        GmVec3(0.182f, 0.364f, 0.364f),
        GmVec3(0.182f, 0.364f, 0.364f),
        GmVec3(0.182f, 0.364f, 0.364f),
        GmVec3(0.439118f, 0.362f, 1.901528f),
        GmVec3(0.968297f, 0.362741f, 1.682276f),
        GmVec3(1.020922f, 0.515218f, 1.038007f),
        GmVec3(0.384841f, 0.905323f, 0.283418f)
    };
    const array<GmVec3> localPositions = {
        GmVec3(0.863012f, 0.3525f, 1.782089f),
        GmVec3(-0.863012f, 0.3525f, 1.782089f),
        GmVec3(0.885002f, 0.352504f, -1.205502f),
        GmVec3(-0.885002f, 0.352504f, -1.205502f),
        GmVec3(0.0f, 0.471253f, 0.219106f),
        GmVec3(0.0f, 0.448782f, -0.20792f),
        GmVec3(0.0f, 0.652812f, -0.89763f),
        GmVec3(-0.015532f, 0.363252f, 1.75357f)
    };
    array<GmMat3> localRotations;
    localRotations.Resize(8);
    localRotations[4].RotateX(Math::ToRad(3.4160502f));
    localRotations[5].RotateX(Math::ToRad(2.6202483f));
    localRotations[6].RotateX(Math::ToRad(2.6874702f));
    localRotations[7].RotateY(Math::ToRad(90.0f));
    localRotations[7].RotateX(Math::ToRad(90.0f));
    localRotations[7].RotateZ(Math::ToRad(-180.0f));
    for (uint i = 0; i < 8; ++i) {
        g_carEllipsoids.Add(Ellipsoid(localPositions[i], radii[i], localRotations[i]));
    }
}

float GmDot(const GmVec3&in a, const GmVec3&in b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

GmVec3 GmScale(const GmVec3&in a, const GmVec3&in b) {
    return GmVec3(a.x * b.x, a.y * b.y, a.z * b.z);
}

GmVec3 FindClosestPointOnPolyToOrigin(const array<vec3>&in transformedVertices, const Polyhedron&in originalPoly) {
    if (transformedVertices.IsEmpty()) return GmVec3(0,0,0);

    float min_dist_sq = 1e18f;
    GmVec3 closest_point;

    for (uint i = 0; i < transformedVertices.Length; i++) {
        float dist_sq = transformedVertices[i].LengthSquared();
        if (dist_sq < min_dist_sq) {
            min_dist_sq = dist_sq;
            closest_point = GmVec3(transformedVertices[i]);
        }
    }

    for (uint i = 0; i < originalPoly.uniqueEdges.Length; i++) {
        const Edge@ edge = originalPoly.uniqueEdges[i];
        GmVec3 vA(transformedVertices[edge.v0]);
        GmVec3 vB(transformedVertices[edge.v1]);

        GmVec3 point_on_edge = closest_point_on_segment_from_origin(vA, vB);
        float dist_sq = point_on_edge.LengthSquared();

        if (dist_sq < min_dist_sq) {
            min_dist_sq = dist_sq;
            closest_point = point_on_edge;
        }
    }

    for (uint i = 0; i < originalPoly.precomputedFaces.Length; ++i) {
        const PrecomputedFace@ face_info = originalPoly.precomputedFaces[i];
        const array<int>@ vertexIndices = face_info.vertexIndices;
        if (vertexIndices.Length < 3) continue;

        GmVec3 v0 = GmVec3(transformedVertices[vertexIndices[0]]);
        GmVec3 v1 = GmVec3(transformedVertices[vertexIndices[1]]);
        GmVec3 v2 = GmVec3(transformedVertices[vertexIndices[2]]);

        GmVec3 face_normal = Cross(v1 - v0, v2 - v0).Normalized();

        float d = GmDot(v0, face_normal);

        if (d * d >= min_dist_sq) {
            continue;
        }

        GmVec3 projectedPoint = face_normal * d;

        bool isInside = true;
        for (uint j = 0; j < vertexIndices.Length; ++j) {
            GmVec3 v_start = GmVec3(transformedVertices[vertexIndices[j]]);
            GmVec3 v_end = GmVec3(transformedVertices[vertexIndices[(j + 1) % vertexIndices.Length]]);
            GmVec3 edge = v_end - v_start;
            GmVec3 to_point = projectedPoint - v_start;

            if (GmDot(Cross(edge, to_point), face_normal) < -EPSILON) {
                isInside = false;
                break;
            }
        }

        if (isInside) {

            min_dist_sq = d * d;
            closest_point = projectedPoint;
        }
    }

    return closest_point;
}

GmVec3 closest_point_on_segment_from_origin(const GmVec3&in a, const GmVec3&in b) {
    GmVec3 ab = b - a;
    float ab_len_sq = ab.LengthSquared();
    if (ab_len_sq < EPSILON * EPSILON) {
        return a;
    }

    float t = -GmDot(a, ab) / ab_len_sq;

    if (t < 0.0f) t = 0.0f;
    if (t > 1.0f) t = 1.0f;

    return a + ab * t;
}

vec3 GetClosestPointOnTransformedPolyhedron(const array<vec3>&in transformedVertices, const Polyhedron&in originalPoly) {
    uint64 polyCheckStartTime = Time::get_Now();
    GmVec3 closestPointGm = FindClosestPointOnPolyToOrigin(transformedVertices, originalPoly);
    g_totalClosestPointPolyTime += (Time::get_Now() - polyCheckStartTime); 

    return closestPointGm.ToVec3();
}

float CalculateMinCarDistanceToPoly_Inner(const GmIso4&in carWorldTransform, const Polyhedron@ targetPoly) {
    if (targetPoly is null || targetPoly.vertices.IsEmpty()) {
        print("Warning: CalculateMinCarDistanceToPoly called with null or empty target polyhedron.", Severity::Warning);
        return 1e18f;
    }

    float minDistanceSqOverall = 1e18f;
    auto simManager = GetSimulationManager();

    uint64 transformStartTime = Time::get_Now();
    GmMat3 carInvRotation = carWorldTransform.m_Rotation.Transposed();
    array<GmVec3> polyVertsInCarSpace(targetPoly.vertices.Length);
    for (uint i = 0; i < targetPoly.vertices.Length; ++i) {
        polyVertsInCarSpace[i] = carInvRotation.Transform(GmVec3(targetPoly.vertices[i]) - carWorldTransform.m_Position);
    }
    g_totalVertexTransformTime += (Time::get_Now() - transformStartTime);

    array<vec3> transformedVertices(targetPoly.vertices.Length);

    for (uint ellipsoidIndex = 0; ellipsoidIndex < g_carEllipsoids.Length; ++ellipsoidIndex) {
        const Ellipsoid@ baseEllipsoid = g_carEllipsoids[ellipsoidIndex];
        GmVec3 localPosition = baseEllipsoid.center;
        GmVec3 invRadii(1.0f / baseEllipsoid.radii.x, 1.0f / baseEllipsoid.radii.y, 1.0f / baseEllipsoid.radii.z);

        if (ellipsoidIndex <= 3) { 

            iso4 wheelSurfaceLocation;
            switch(ellipsoidIndex) {
                case 0: wheelSurfaceLocation = simManager.Wheels.FrontLeft.SurfaceHandler.Location; break;
                case 1: wheelSurfaceLocation = simManager.Wheels.FrontRight.SurfaceHandler.Location; break;
                case 2: wheelSurfaceLocation = simManager.Wheels.BackLeft.SurfaceHandler.Location; break;
                case 3: wheelSurfaceLocation = simManager.Wheels.BackRight.SurfaceHandler.Location; break;
            }
            localPosition = GmVec3(wheelSurfaceLocation.Position);
        }

        if (ellipsoidIndex <= 3) { 
             for(uint i = 0; i < targetPoly.vertices.Length; ++i) {
                GmVec3 v_relative_to_wheel = polyVertsInCarSpace[i] - localPosition;
                GmVec3 v_scaled = GmScale(v_relative_to_wheel, invRadii);
                transformedVertices[i] = vec3(v_scaled.x, v_scaled.y, v_scaled.z);
            }
        } else { 
            GmMat3 localInvRotation = baseEllipsoid.rotation.Transposed();
            for(uint i = 0; i < targetPoly.vertices.Length; ++i) {
                GmVec3 v_relative_to_ellipsoid = polyVertsInCarSpace[i] - localPosition;
                GmVec3 v_rotated = localInvRotation.Transform(v_relative_to_ellipsoid);
                GmVec3 v_scaled = GmScale(v_rotated, invRadii);
                transformedVertices[i] = vec3(v_scaled.x, v_scaled.y, v_scaled.z);
            }
        }

        GmVec3 p_poly_transformed(GetClosestPointOnTransformedPolyhedron(transformedVertices, targetPoly));

        if (p_poly_transformed.LengthSquared() < 1.0f - EPSILON) {
            return 0.0f; 
        }

        GmVec3 p_sphere_transformed = p_poly_transformed.Normalized();

        GmVec3 p_poly_world_offset, p_sphere_world_offset;

        if (ellipsoidIndex <= 3) { 
            p_poly_world_offset = GmScale(p_poly_transformed, baseEllipsoid.radii) + localPosition;
            p_sphere_world_offset = GmScale(p_sphere_transformed, baseEllipsoid.radii) + localPosition;
        } else { 
            p_poly_world_offset = baseEllipsoid.rotation.Transform(GmScale(p_poly_transformed, baseEllipsoid.radii)) + localPosition;
            p_sphere_world_offset = baseEllipsoid.rotation.Transform(GmScale(p_sphere_transformed, baseEllipsoid.radii)) + localPosition;
        }

        GmVec3 p_poly_world = carWorldTransform.m_Rotation.Transform(p_poly_world_offset) + carWorldTransform.m_Position;
        GmVec3 p_sphere_world = carWorldTransform.m_Rotation.Transform(p_sphere_world_offset) + carWorldTransform.m_Position;

        float distanceSq = (p_poly_world - p_sphere_world).LengthSquared();
        if (distanceSq < minDistanceSqOverall) {
            minDistanceSqOverall = distanceSq;
        }
    }

    return Math::Sqrt(minDistanceSqOverall);
}

float CalculateMinCarDistanceToPoly(const GmIso4&in carWorldTransform, const Polyhedron@ targetPoly) {
    uint64 funcStartTime = Time::get_Now();
    float result = CalculateMinCarDistanceToPoly_Inner(carWorldTransform, targetPoly);
    g_totalCalcMinCarDistTime += (Time::get_Now() - funcStartTime);
    return result;
}

Polyhedron ClipPolyhedronByPlane(const Polyhedron& in poly, const vec3& in clipPlaneNormal, const vec3& in clipPlanePoint)
{
    if (poly.vertices.IsEmpty()) return poly;

    array<vec3> newVertices;
    array<array<int>> newFaces;
    dictionary vertexMap; 

    array<float> vertexDists(poly.vertices.Length);
    for (uint i = 0; i < poly.vertices.Length; i++) {
        vertexDists[i] = Math::Dot(poly.vertices[i] - clipPlanePoint, clipPlaneNormal);
    }

    for (uint faceIdx = 0; faceIdx < poly.faces.Length; faceIdx++) {
        const array<int>@ face = poly.faces[faceIdx];
        if (face.Length < 3) continue;

        array<int> newPolygonIndices; 

        for (uint i = 0; i < face.Length; i++) {
            int currOriginalIdx = face[i];
            int nextOriginalIdx = face[(i + 1) % face.Length];

            float currDist = vertexDists[currOriginalIdx];
            float nextDist = vertexDists[nextOriginalIdx];

            if (currDist <= EPSILON) {
                string key = "" + currOriginalIdx;
                int newIdx;
                if (!vertexMap.Get(key, newIdx)) {
                    newIdx = newVertices.Length;
                    vertexMap.Set(key, newIdx);
                    newVertices.Add(poly.vertices[currOriginalIdx]);
                }

                if (newPolygonIndices.IsEmpty() || newPolygonIndices[newPolygonIndices.Length-1] != newIdx) {
                    newPolygonIndices.Add(newIdx);
                }
            }

            if ((currDist > 0 && nextDist < 0) || (currDist < 0 && nextDist > 0)) {
                float t = currDist / (currDist - nextDist);
                vec3 intersectionPoint = poly.vertices[currOriginalIdx] + (poly.vertices[nextOriginalIdx] - poly.vertices[currOriginalIdx]) * t;

                int newIdx = newVertices.Length;
                newVertices.Add(intersectionPoint);

                if (newPolygonIndices.IsEmpty() || newPolygonIndices[newPolygonIndices.Length-1] != newIdx) {
                    newPolygonIndices.Add(newIdx);
                }
            }
        }

        if (newPolygonIndices.Length >= 3) {
            for (uint i = 1; i < newPolygonIndices.Length - 1; i++) {
                array<int> newTriangle = {
                    newPolygonIndices[0],
                    newPolygonIndices[i],
                    newPolygonIndices[i + 1]
                };
                newFaces.Add(newTriangle);
            }
        }
    }

    Polyhedron clippedPoly(newVertices, newFaces);
    return clippedPoly;
}

Polyhedron ClipPolyhedronByAABB(const Polyhedron& in poly, const AABB& in box)
{
    Polyhedron clippedPoly = poly;

    clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3(-1, 0, 0), box.min); 
    clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3( 1, 0, 0), box.max); 
    clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3( 0,-1, 0), box.min); 
    clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3( 0, 1, 0), box.max); 
    clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3( 0, 0,-1), box.min); 
    clippedPoly = ClipPolyhedronByPlane(clippedPoly, vec3( 0, 0, 1), box.max); 

    return clippedPoly;
}
class GmVec3 {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    GmVec3() {}
    GmVec3(float num) {
        this.x = num;
        this.y = num;
        this.z = num;
    }
    GmVec3(float x, float y, float z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
    GmVec3(const GmVec3&in other) {
        this.x = other.x;
        this.y = other.y;
        this.z = other.z;
    }
    GmVec3(const vec3&in other) {
        this.x = other.x;
        this.y = other.y;
        this.z = other.z;
    }
    vec3 ToVec3() const {
        return vec3(x, y, z);
    }
    void Mult(const GmMat3&in M) {
        float _x = x * M.x.x + y * M.x.y + z * M.x.z;
        float _y = x * M.y.x + y * M.y.y + z * M.y.z;
        float _z = x * M.z.x + y * M.z.y + z * M.z.z;
        x = _x;
        y = _y;
        z = _z;
    }
    void Mult(const GmIso4&in T) {
        Mult(T.m_Rotation);
        x += T.m_Position.x;
        y += T.m_Position.y;
        z += T.m_Position.z;
    }
    void MultTranspose(const GmMat3&in M) {
        float _x = x * M.x.x + y * M.y.x + z * M.z.x;
        float _y = x * M.x.y + y * M.y.y + z * M.z.y;
        float _z = x * M.x.z + y * M.y.z + z * M.z.z;
        x = _x;
        y = _y;
        z = _z;
    }
    float LengthSquared() const {
        return x*x + y*y + z*z;
    }
    float Length() const {
        return Math::Sqrt(LengthSquared());
    }
    void Normalize() {
        float len = Length();
        if (len > 1e-6f) {
            x /= len;
            y /= len;
            z /= len;
        }
    }
    GmVec3 Normalized() const {
        GmVec3 result = this;
        result.Normalize();
        return result;
    }
    GmVec3 opAdd(const GmVec3&in other) const {
        return GmVec3(x + other.x, y + other.y, z + other.z);
    }
    GmVec3 opSub(const GmVec3&in other) const {
        return GmVec3(x - other.x, y - other.y, z - other.z);
    }
    GmVec3 opMul(float scalar) const {
        return GmVec3(x * scalar, y * scalar, z * scalar);
    }
    GmVec3 opDiv(float scalar) const {
        return GmVec3(x / scalar, y / scalar, z / scalar);
    }
    GmVec3 opNeg() const {
        return GmVec3(-x, -y, -z);
    }
    void opAddAssign(const GmVec3&in other) {
        x += other.x; y += other.y; z += other.z;
    }
    void opSubAssign(const GmVec3&in other) {
        x -= other.x; y -= other.y; z -= other.z;
    }
    void opMulAssign(float scalar) {
        x *= scalar; y *= scalar; z *= scalar;
    }
    void opDivAssign(float scalar) {
        x /= scalar; y /= scalar; z /= scalar;
    }
    GmVec3 opMul_Elementwise(const GmVec3&in other) const {
        return GmVec3(x * other.x, y * other.y, z * other.z);
    }
    GmVec3 opDiv_Elementwise(const GmVec3&in other) const {
        return GmVec3(x / other.x, y / other.y, z / other.z);
    }
}
class GmMat3 {
    GmVec3 x;
    GmVec3 y;
    GmVec3 z;
    GmMat3() { SetIdentity(); }
    GmMat3(const GmMat3&in other) {
        this.x = other.x;
        this.y = other.y;
        this.z = other.z;
    }
    GmMat3(const GmVec3&in x, const GmVec3&in y, const GmVec3&in z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
    GmMat3(const mat3&in other) {
        this.x.x = other.x.x;
        this.x.y = other.y.x;
        this.x.z = other.z.x;
        this.y.x = other.x.y;
        this.y.y = other.y.y;
        this.y.z = other.z.y;
        this.z.x = other.x.z;
        this.z.y = other.y.z;
        this.z.z = other.z.z;
    }
    mat3 ToMat3() const {
        mat3 m;
        m.x.x = this.x.x; m.x.y = this.y.x; m.x.z = this.z.x;
        m.y.x = this.x.y; m.y.y = this.y.y; m.y.z = this.z.y;
        m.z.x = this.x.z; m.z.y = this.y.z; m.z.z = this.z.z;
        return m;
    }
    void SetIdentity() {
        x = GmVec3(1.0f, 0.0f, 0.0f);
        y = GmVec3(0.0f, 1.0f, 0.0f);
        z = GmVec3(0.0f, 0.0f, 1.0f);
    }
    void Mult(const GmMat3&in other) {
        GmMat3 result;
        result.x.x = x.x * other.x.x + y.x * other.x.y + z.x * other.x.z;
        result.x.y = x.y * other.x.x + y.y * other.x.y + z.y * other.x.z;
        result.x.z = x.z * other.x.x + y.z * other.x.y + z.z * other.x.z;
        result.y.x = x.x * other.y.x + y.x * other.y.y + z.x * other.y.z;
        result.y.y = x.y * other.y.x + y.y * other.y.y + z.y * other.y.z;
        result.y.z = x.z * other.y.x + y.z * other.y.y + z.z * other.y.z;
        result.z.x = x.x * other.z.x + y.x * other.z.y + z.x * other.z.z;
        result.z.y = x.y * other.z.x + y.y * other.z.y + z.y * other.z.z;
        result.z.z = x.z * other.z.x + y.z * other.z.y + z.z * other.z.z;
        this = result;
    }
    GmMat3 opMul(const GmMat3&in other) const {
        GmMat3 result = this;
        result.Mult(other);
        return result;
    }
    GmVec3 Transform(const GmVec3&in v) const {
        return GmVec3(
            x.x * v.x + y.x * v.y + z.x * v.z,
            x.y * v.x + y.y * v.y + z.y * v.z,
            x.z * v.x + y.z * v.y + z.z * v.z
        );
    }
    GmVec3 opMul(const GmVec3&in v) const {
        return Transform(v);
    }
     GmVec3 TransformTranspose(const GmVec3&in v) const {
        return GmVec3(
            x.x * v.x + x.y * v.y + x.z * v.z,
            y.x * v.x + y.y * v.y + y.z * v.z,
            z.x * v.x + z.y * v.y + z.z * v.z
        );
    }
    void RotateX(float rad) {
        float s = Math::Sin(rad);
        float c = Math::Cos(rad);
        GmMat3 rotMat(
            GmVec3(1, 0, 0),
            GmVec3(0, c, s),
            GmVec3(0,-s, c)
        );
        Mult(rotMat);
    }
    void RotateY(float rad) {
        float s = Math::Sin(rad);
        float c = Math::Cos(rad);
         GmMat3 rotMat(
            GmVec3(c, 0,-s),
            GmVec3(0, 1, 0),
            GmVec3(s, 0, c)
        );
        Mult(rotMat);
    }
    void RotateZ(float rad) {
        float s = Math::Sin(rad);
        float c = Math::Cos(rad);
         GmMat3 rotMat(
            GmVec3(c, s, 0),
            GmVec3(-s,c, 0),
            GmVec3(0, 0, 1)
        );
        Mult(rotMat);
    }
    float Determinant() const {
        return x.x * (y.y * z.z - y.z * z.y)
             - y.x * (x.y * z.z - x.z * z.y)
             + z.x * (x.y * y.z - x.z * y.y);
    }
    GmMat3 Inverse() const {
        GmMat3 inv;
        float det = Determinant();
        if (Math::Abs(det) < 1e-6f) {
            print("Warning: GmMat3::Inverse() called on singular matrix. Returning identity.", Severity::Warning);
            return inv;
        }
        float invDet = 1.0f / det;
        inv.x.x = (y.y * z.z - y.z * z.y) * invDet;
        inv.y.x = (y.z * z.x - y.x * z.z) * invDet;
        inv.z.x = (y.x * z.y - y.y * z.x) * invDet;
        inv.x.y = (x.z * z.y - x.y * z.z) * invDet;
        inv.y.y = (x.x * z.z - x.z * z.x) * invDet;
        inv.z.y = (x.y * z.x - x.x * z.y) * invDet;
        inv.x.z = (x.y * y.z - x.z * y.y) * invDet;
        inv.y.z = (x.z * y.x - x.x * y.z) * invDet;
        inv.z.z = (x.x * y.y - x.y * y.x) * invDet;
        return inv;
    }
    GmMat3 Transposed() const {
        GmMat3 result;
        result.x.x = x.x; result.y.x = x.y; result.z.x = x.z;
        result.x.y = y.x; result.y.y = y.y; result.z.y = y.z;
        result.x.z = z.x; result.y.z = z.y; result.z.z = z.z;
        return result;
    }
}
class GmIso4 {
    GmMat3 m_Rotation;
    GmVec3 m_Position;
    GmIso4() {}
    GmIso4(const GmIso4&in other) {
        this.m_Rotation = other.m_Rotation;
        this.m_Position = other.m_Position;
    }
    GmIso4(const GmMat3&in rotation, const GmVec3&in position) {
        this.m_Rotation = rotation;
        this.m_Position = position;
    }
    GmIso4(const iso4&in other) {
        this.m_Rotation = GmMat3(other.Rotation);
        this.m_Position = GmVec3(other.Position);
    }
    iso4 ToIso4() const {
        iso4 result;
        result.Rotation = m_Rotation.ToMat3();
        result.Position = m_Position.ToVec3();
        return result;
    }
    void Mult(const GmIso4&in other) {
        m_Position = m_Rotation.Transform(other.m_Position) + m_Position;
        m_Rotation.Mult(other.m_Rotation);
    }
    GmIso4 opMul(const GmIso4&in other) const {
        GmIso4 result = this;
        result.Mult(other);
        return result;
    }
    GmVec3 Transform(const GmVec3&in p) const {
        return m_Rotation.Transform(p) + m_Position;
    }
    GmVec3 opMul(const GmVec3&in p) const {
        return Transform(p);
    }
    GmVec3 TransformDirection(const GmVec3&in d) const {
        return m_Rotation.Transform(d);
    }
    GmIso4 Inverse() const {
        GmMat3 invRot = m_Rotation.Inverse();
        GmVec3 invPos = invRot.Transform(-m_Position);
        return GmIso4(invRot, invPos);
    }
}
class AABB {
    vec3 min = vec3(-1e9, -1e9, -1e9);
    vec3 max = vec3(1e9, 1e9, 1e9);
    AABB() {}
    AABB(const vec3&in min, const vec3&in max) {
        this.min = min;
        this.max = max;
    }
    void Add(const vec3&in p) {
        min.x = Math::Min(min.x, p.x);
        min.y = Math::Min(min.y, p.y);
        min.z = Math::Min(min.z, p.z);
        max.x = Math::Max(max.x, p.x);
        max.y = Math::Max(max.y, p.y);
        max.z = Math::Max(max.z, p.z);
    }
    void Add(const AABB&in other) {
        Add(other.min);
        Add(other.max);
    }
    vec3 Center() const {
        return (min + max) * 0.5f;
    }
    vec3 Size() const {
        return max - min;
    }
    bool Contains(const vec3&in p, float margin = 1e-6f) const {
        return (p.x >= min.x - margin && p.x <= max.x + margin &&
                p.y >= min.y - margin && p.y <= max.y + margin &&
                p.z >= min.z - margin && p.z <= max.z + margin);
    }
    float DistanceToPoint(const vec3&in p) const {
        float dx = Math::Max(min.x - p.x, 0.0f) + Math::Max(p.x - max.x, 0.0f);
        float dy = Math::Max(min.y - p.y, 0.0f) + Math::Max(p.y - max.y, 0.0f);
        float dz = Math::Max(min.z - p.z, 0.0f) + Math::Max(p.z - max.z, 0.0f);
        return Math::Sqrt(dx*dx + dy*dy + dz*dz);
    }
    AABB Intersect(const AABB& other) const {
        vec3 intersectMin = vec3(
            Math::Max(min.x, other.min.x),
            Math::Max(min.y, other.min.y),
            Math::Max(min.z, other.min.z)
        );
        vec3 intersectMax = vec3(
            Math::Min(max.x, other.max.x),
            Math::Min(max.y, other.max.y),
            Math::Min(max.z, other.max.z)
        );
        return AABB(intersectMin, intersectMax);
    }
    bool IsValid() const {
        return min.x <= max.x && min.y <= max.y && min.z <= max.z;
    }
    bool intersectsSegment(const vec3&in p0, const vec3&in p1) const {
        vec3 d = p1 - p0;
        float tmin = 0.0f;
        float tmax = 1.0f;
        for (int i = 0; i < 3; ++i) {
            if (Math::Abs(d[i]) < 1e-6f) {
                if (p0[i] < min[i] || p0[i] > max[i]) return false;
            } else {
                float ood = 1.0f / d[i];
                float t1 = (min[i] - p0[i]) * ood;
                float t2 = (max[i] - p0[i]) * ood;
                if (t1 > t2) {
                    float temp = t1;
                    t1 = t2;
                    t2 = temp;
                }
                tmin = Math::Max(tmin, t1);
                tmax = Math::Min(tmax, t2);
                if (tmin > tmax) return false;
            }
        }
        return true;
    }
    bool testAxis(const vec3&in v0, const vec3&in v1, const vec3&in v2, const vec3&in edge, const vec3&in boxHalf, const int axis) {
        float p, minTri, maxTri, rad;
        if (axis == 0) {
            p = v0.z * edge.y - v0.y * edge.z;
            minTri = p; maxTri = p;
            p = v1.z * edge.y - v1.y * edge.z;
            minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
            p = v2.z * edge.y - v2.y * edge.z;
            minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
            rad = Math::Abs(edge.y) * boxHalf.z + Math::Abs(edge.z) * boxHalf.y;
        } else if (axis == 1) {
            p = v0.x * edge.z - v0.z * edge.x;
            minTri = p; maxTri = p;
            p = v1.x * edge.z - v1.z * edge.x;
            minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
            p = v2.x * edge.z - v2.z * edge.x;
            minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
            rad = Math::Abs(edge.x) * boxHalf.z + Math::Abs(edge.z) * boxHalf.x;
        } else {
            p = v0.y * edge.x - v0.x * edge.y;
            minTri = p; maxTri = p;
            p = v1.y * edge.x - v1.x * edge.y;
            minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
            p = v2.y * edge.x - v2.x * edge.y;
            minTri = Math::Min(minTri, p); maxTri = Math::Max(maxTri, p);
            rad = Math::Abs(edge.x) * boxHalf.y + Math::Abs(edge.y) * boxHalf.x;
        }
        return !(minTri > rad || maxTri < -rad);
    }
    bool intersectsTriangle(const vec3&in p0, const vec3&in p1, const vec3&in p2) const {

        vec3 boxCenter = (min + max) * 0.5f;
        vec3 boxHalf = (max - min) * 0.5f;

        vec3 v0 = p0 - boxCenter;
        vec3 v1 = p1 - boxCenter;
        vec3 v2 = p2 - boxCenter;

        vec3 e0 = v1 - v0;
        vec3 e1 = v2 - v1;
        vec3 e2 = v0 - v2;

        if (!testAxis(v0, v1, v2, e0, boxHalf, 0)) return false;
        if (!testAxis(v0, v1, v2, e0, boxHalf, 1)) return false;
        if (!testAxis(v0, v1, v2, e0, boxHalf, 2)) return false;
        if (!testAxis(v0, v1, v2, e1, boxHalf, 0)) return false;
        if (!testAxis(v0, v1, v2, e1, boxHalf, 1)) return false;
        if (!testAxis(v0, v1, v2, e1, boxHalf, 2)) return false;
        if (!testAxis(v0, v1, v2, e2, boxHalf, 0)) return false;
        if (!testAxis(v0, v1, v2, e2, boxHalf, 1)) return false;
        if (!testAxis(v0, v1, v2, e2, boxHalf, 2)) return false;

        for (int i = 0; i < 3; i++) {
            float triMin = Math::Min(v0[i], Math::Min(v1[i], v2[i]));
            float triMax = Math::Max(v0[i], Math::Max(v1[i], v2[i]));
            if (triMin > boxHalf[i] || triMax < -boxHalf[i])
                return false;
        }

        vec3 normal = Cross(e0, e1);

        float rad = boxHalf.x * Math::Abs(normal.x) + boxHalf.y * Math::Abs(normal.y) + boxHalf.z * Math::Abs(normal.z);

        float triProj0 = Math::Dot(normal, v0);
        float triProj1 = Math::Dot(normal, v1);
        float triProj2 = Math::Dot(normal, v2);
        float triMin = Math::Min(triProj0, Math::Min(triProj1, triProj2));
        float triMax = Math::Max(triProj0, Math::Max(triProj1, triProj2));
        if (triMin > rad || triMax < -rad)
            return false;

        return true;
    }

    string ToString() {
        return "AABB(min: " + min.x + ", " + min.y + ", " + min.z +
               ", max: " + max.x + ", " + max.y + ", " + max.z + ")";
    }
}

class Edge {
    int v0;
    int v1;
    Edge() {
        v0 = -1;
        v1 = -1;
    }
    Edge(int i0 = -1, int i1 = -1) {

        if (i0 < i1) {
            v0 = i0;
            v1 = i1;
        } else {
            v0 = i1;
            v1 = i0;
        }
    }
    bool opEquals(const Edge&in other) const {
        return v0 == other.v0 && v1 == other.v1;
    }
    bool opLess(const Edge&in other) const {
        if (v0 < other.v0) return true;
        if (v0 > other.v0) return false;
        return v1 < other.v1;
    }
}

class SortableVertex {
    float angle;
    int index;

    int opCmp(const SortableVertex&in other) const {
        if (angle < other.angle) return -1;
        if (angle > other.angle) return 1;
        return 0;
    }
};

class PrecomputedFace {
    array<int> vertexIndices;
    GmVec3 normal;
    GmVec3 planePoint; 
}

class Polyhedron {
    array<vec3> vertices;
    array<array<int>> faces;
    array<PrecomputedFace> precomputedFaces; 
    array<Edge> uniqueEdges;

    Polyhedron() {}

Polyhedron(const array<vec3>&in in_vertices, const array<array<int>>&in triangleFaces) {
    this.vertices = in_vertices;

    if (vertices.IsEmpty() || triangleFaces.IsEmpty()) {
        return;
    }

    uint numTriangles = triangleFaces.Length;
    array<array<int>> newFaceIndices;
    array<PrecomputedFace> newPrecomputedFaces; 

    dictionary edgeToGlobalFaces;
    array<vec3> faceNormals(numTriangles);

    for (uint i = 0; i < numTriangles; ++i) {
        const array<int>@ face_idxs = triangleFaces[i];
        if (face_idxs.Length != 3) {
            print("Error: Input face " + i + " is not a triangle. Simplification requires a triangle mesh.", Severity::Error);
            return;
        }

        vec3 edge1 = vertices[face_idxs[1]] - vertices[face_idxs[0]];
        vec3 edge2 = vertices[face_idxs[2]] - vertices[face_idxs[0]];
        faceNormals[i] = Cross(edge1, edge2).Normalized();

        for (uint j = 0; j < 3; ++j) {
            Edge e(face_idxs[j], face_idxs[(j + 1) % 3]);
            string edgeKey = e.v0 + "_" + e.v1;

            array<int>@ faceList;
            if (!edgeToGlobalFaces.Get(edgeKey, @faceList)) {
                edgeToGlobalFaces.Set(edgeKey, array<int> = {int(i)});
            } else {
                faceList.Add(i);
            }
        }
    }

    array<bool> processedFaces(numTriangles); 
    const float COPLANAR_TOLERANCE = 0.9999f;

    for (uint i = 0; i < numTriangles; ++i) {
        if (processedFaces[i]) continue;

        array<int> componentQueue = {int(i)};
        array<int> componentFaces = {int(i)};
        processedFaces[i] = true;
        uint head = 0;
        const vec3 referenceNormal = faceNormals[i];

        while (head < componentQueue.Length) {
            int currentIdx = componentQueue[head++];
            const array<int>@ currentFace = triangleFaces[currentIdx];

            for (uint j = 0; j < 3; ++j) {
                Edge e(currentFace[j], currentFace[(j + 1) % 3]);
                string edgeKey = e.v0 + "_" + e.v1;

                array<int>@ neighborFaces;
                if(edgeToGlobalFaces.Get(edgeKey, @neighborFaces)) {
                    for (uint k = 0; k < neighborFaces.Length; ++k) {
                        int neighborIdx = neighborFaces[k];
                        if (!processedFaces[neighborIdx] && Math::Dot(referenceNormal, faceNormals[neighborIdx]) > COPLANAR_TOLERANCE) {
                            processedFaces[neighborIdx] = true;
                            componentFaces.Add(neighborIdx);
                            componentQueue.Add(neighborIdx);
                        }
                    }
                }
            }
        }

        dictionary boundaryEdges;
        dictionary vertToBoundaryEdges;

        for(uint c_idx = 0; c_idx < componentFaces.Length; ++c_idx) {
            int triFaceIdx = componentFaces[c_idx];
            const array<int>@ triVerts = triangleFaces[triFaceIdx];
            for (uint v_idx = 0; v_idx < 3; ++v_idx) {
                Edge e(triVerts[v_idx], triVerts[(v_idx+1)%3]);
                string edgeKey = e.v0 + "_" + e.v1;

                array<int>@ globalFaces;
                edgeToGlobalFaces.Get(edgeKey, @globalFaces);

                int sharedCoplanarFaces = 0;
                for(uint g_idx = 0; g_idx < globalFaces.Length; ++g_idx) {
                    if(componentFaces.Find(globalFaces[g_idx]) != -1) {
                        sharedCoplanarFaces++;
                    }
                }

                if(sharedCoplanarFaces == 1) {
                    if (!boundaryEdges.Exists(edgeKey)) {
                        boundaryEdges.Set(edgeKey, e);

                        array<Edge>@ v0_edges;
                        if (!vertToBoundaryEdges.Get(""+e.v0, @v0_edges)) {
                            @v0_edges = array<Edge>();
                            vertToBoundaryEdges.Set(""+e.v0, @v0_edges);
                        }
                        v0_edges.Add(e);

                        array<Edge>@ v1_edges;
                        if (!vertToBoundaryEdges.Get(""+e.v1, @v1_edges)) {
                            @v1_edges = array<Edge>();
                            vertToBoundaryEdges.Set(""+e.v1, @v1_edges);
                        }
                        v1_edges.Add(e);
                    }
                }
            }
        }

        array<string>@ boundaryEdgeKeys = boundaryEdges.GetKeys();
        if (boundaryEdgeKeys.Length < 3) continue;

        array<int> sortedIndices;
        Edge startEdge;
        boundaryEdges.Get(boundaryEdgeKeys[0], startEdge);

        sortedIndices.Add(startEdge.v0);
        sortedIndices.Add(startEdge.v1);

        dictionary usedEdgeKeys;
        usedEdgeKeys.Set(boundaryEdgeKeys[0], true);

        int currentVert = startEdge.v1;
        int startVert = startEdge.v0;

        while(currentVert != startVert && sortedIndices.Length <= boundaryEdgeKeys.Length) {
            array<Edge>@ connectedEdges;
            vertToBoundaryEdges.Get(""+currentVert, @connectedEdges);

            bool foundNext = false;
            for(uint edge_idx = 0; edge_idx < connectedEdges.Length; ++edge_idx) {
                Edge nextEdge = connectedEdges[edge_idx];
                string nextEdgeKey = nextEdge.v0 + "_" + nextEdge.v1;

                if (!usedEdgeKeys.Exists(nextEdgeKey)) {
                    usedEdgeKeys.Set(nextEdgeKey, true);

                    currentVert = (nextEdge.v0 == currentVert) ? nextEdge.v1 : nextEdge.v0;
                    sortedIndices.Add(currentVert);
                    foundNext = true;
                    break;
                }
            }
            if (!foundNext) {

                print("Error: Could not find next edge in chain for merged face.", Severity::Error);
                break;
            }
        }

        if(sortedIndices.Length > 0 && sortedIndices[sortedIndices.Length-1] == startVert) {
            sortedIndices.RemoveAt(sortedIndices.Length - 1);
        }

        if (sortedIndices.Length < 3) continue;

        newFaceIndices.Add(sortedIndices);

        PrecomputedFace pface;
        pface.vertexIndices = sortedIndices;
        pface.normal = GmVec3(referenceNormal);
        pface.planePoint = GmVec3(vertices[sortedIndices[0]]);
        newPrecomputedFaces.Add(pface);
    }

    this.faces = newFaceIndices;
    this.precomputedFaces = newPrecomputedFaces; 

    if (vertices.IsEmpty() || this.faces.IsEmpty()) return;

    uint numFaces = this.faces.Length;
    array<Edge> allEdgesTemp;
    for (uint i = 0; i < numFaces; ++i) {
        const array<int>@ faceIndices = this.faces[i];
        uint faceVertCount = faceIndices.Length;
        if (faceVertCount < 2) continue;
        for(uint v_idx = 0; v_idx < faceVertCount; ++v_idx) {
            int i0 = faceIndices[v_idx];
            int i1 = faceIndices[(v_idx + 1) % faceVertCount];
            allEdgesTemp.Add(Edge(i0, i1));
        }
    }

    if (!allEdgesTemp.IsEmpty()) {
        allEdgesTemp.SortAsc();
        uniqueEdges.Add(allEdgesTemp[0]);
        for (uint i = 1; i < allEdgesTemp.Length; ++i) {
            if (!(allEdgesTemp[i] == uniqueEdges[uniqueEdges.Length - 1])) {
                 uniqueEdges.Add(allEdgesTemp[i]);
            }
        }
    }
}

    bool GetFaceVertices(uint faceIndex, array<vec3>&out faceVerts) const {
        if (faceIndex >= faces.Length) return false;
        const array<int>@ indices = faces[faceIndex];
        faceVerts.Resize(indices.Length);
        for(uint i = 0; i < indices.Length; ++i) {
            int vertexIndex = indices[i];
            if (vertexIndex < 0 || vertexIndex >= int(vertices.Length)) return false;
            faceVerts[i] = vertices[vertexIndex];
        }
        return true;
    }

    GmVec3 GetClosestPoint(const GmVec3&in p) const {
        if (precomputedFaces.IsEmpty()) {
            if (vertices.IsEmpty()) return p;

            GmVec3 closest_v(vertices[0].x, vertices[0].y, vertices[0].z);
            float min_dist_sq = (p - closest_v).LengthSquared();
            for (uint i = 1; i < vertices.Length; ++i) {
                GmVec3 current_v(vertices[i].x, vertices[i].y, vertices[i].z);
                float dist_sq = (p - current_v).LengthSquared();
                if (dist_sq < min_dist_sq) {
                    min_dist_sq = dist_sq;
                    closest_v = current_v;
                }
            }
            return closest_v;
        }

        GmVec3 closest_point_overall;
        float min_dist_sq = 1e18f;
        bool first_face = true;

        for (uint i = 0; i < precomputedFaces.Length; ++i) {
            const PrecomputedFace@ face = precomputedFaces[i];

            GmVec3 projectedPoint = p - face.normal * GmDot(p - face.planePoint, face.normal);

            bool isInside = true;
            for (uint j = 0; j < face.vertexIndices.Length; ++j) {
                GmVec3 v_start = GmVec3(vertices[face.vertexIndices[j]]);
                GmVec3 v_end = GmVec3(vertices[face.vertexIndices[(j + 1) % face.vertexIndices.Length]]);
                GmVec3 edge = v_end - v_start;
                GmVec3 to_point = projectedPoint - v_start;

                if (GmDot(Cross(edge, to_point), face.normal) < -EPSILON) {
                    isInside = false;
                    break;
                }
            }

            GmVec3 point_on_face;
            if (isInside) {
                point_on_face = projectedPoint;
            } else {
                GmVec3 v_last = GmVec3(vertices[face.vertexIndices[face.vertexIndices.Length - 1]]);
                GmVec3 v_first = GmVec3(vertices[face.vertexIndices[0]]);
                point_on_face = closest_point_on_segment(p, v_last, v_first);
                float min_edge_dist_sq = (p - point_on_face).LengthSquared();

                for (uint j = 0; j < face.vertexIndices.Length - 1; ++j) {
                    GmVec3 v_start = GmVec3(vertices[face.vertexIndices[j]]);
                    GmVec3 v_end = GmVec3(vertices[face.vertexIndices[j + 1]]);
                    GmVec3 edge_point = closest_point_on_segment(p, v_start, v_end);
                    float dist_sq = (p - edge_point).LengthSquared();
                    if (dist_sq < min_edge_dist_sq) {
                        min_edge_dist_sq = dist_sq;
                        point_on_face = edge_point;
                    }
                }
            }

            float dist_sq = (p - point_on_face).LengthSquared();
            if (first_face || dist_sq < min_dist_sq) {
                min_dist_sq = dist_sq;
                closest_point_overall = point_on_face;
                first_face = false;
            }
        }
        return closest_point_overall;
    }

    bool GetFaceNormal(uint faceIndex, GmVec3&out normal) const {

        if (faceIndex >= precomputedFaces.Length) return false;
        normal = precomputedFaces[faceIndex].normal;
        return true;
    }
};

class Ellipsoid {
    GmVec3 center;
    GmVec3 radii;
    GmMat3 rotation;
    Ellipsoid() {
        center = GmVec3(0,0,0);
        radii = GmVec3(1,1,1);
    }
    Ellipsoid(const GmVec3&in center, const GmVec3&in radii, const GmMat3&in rotation) {
        this.center = center;
        this.radii = radii;
        this.rotation = rotation;
    }
     Ellipsoid(const vec3&in center, const vec3&in radii, const mat3&in rotation) {
        this.center = GmVec3(center);
        this.radii = GmVec3(radii);
        this.rotation = GmMat3(rotation);
    }

}
GmVec3 closest_point_on_segment(const GmVec3&in p, const GmVec3&in a, const GmVec3&in b) {
    GmVec3 ab = b - a;
    float ab_len_sq = ab.LengthSquared();
    if (ab_len_sq < EPSILON * EPSILON) {
        return a;
    }
    float t = GmDot(p - a, ab) / ab_len_sq;
    t = Math::Max(0.0f, Math::Min(1.0f, t));
    return a + ab * t;
}
