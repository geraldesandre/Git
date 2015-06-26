function VisualServoTest
    initTestSuite;
    
    
function pbvs_test
    
    cam = CentralCamera('default');
    Tc0 = transl(1,1,-3)*trotz(0.6);
    TcStar_t = transl(0, 0, 1);
    pbvs = PBVS(cam, 'T0', Tc0, 'Tf', TcStar_t);
    pbvs
    pbvs.run
    pbvs.plot_p
    pbvs.plot_vel
    pbvs.plot_camera
    
    close all
    
function ibvs_test
    
    cam = CentralCamera('default');
    Tc0 = transl(1,1,-3)*trotz(0.6);
    pStar = bsxfun(@plus, 200*[-1 -1 1 1; -1 1 1 -1], cam.pp');
    ibvs = IBVS(cam, 'T0', Tc0, 'pstar', pStar);
    ibvs
    ibvs.run();
    ibvs.plot_p();
    ibvs.plot_vel();
    ibvs.plot_camera();
    ibvs.plot_jcond();
    
    ibvs = IBVS(cam, 'T0', Tc0, 'pstar', pStar, 'depth', 1)
    ibvs.run();
    
    ibvs = IBVS(cam, 'T0', Tc0, 'pstar', pStar, 'depthest')
    ibvs.run();
    
        close all

    
function ibvs_line
    cam = CentralCamera('default');
    
    ibvs = IBVS_l(cam, 'example'); 
    ibvs.run()
    
        close all

function ibvs_circle
    cam = CentralCamera('default');
    
    ibvs = IBVS_e(cam, 'example'); 
    ibvs.run()
    
        close all
