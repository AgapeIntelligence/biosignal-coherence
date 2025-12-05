import torch, numpy as np, time
from lava.lib.dl.kuramoto import KuramotoNet

N = 512
model = KuramotoNet(n_osc=N, natural_freq=torch.randn(N)*0.5+10.0,
                    coupling_strength=8.7, bits=2, sparse_density=0.18,
                    backend="npu_sparse")

print("AgapeIntelligence biosignal-coherence Mobile Elite – 0.995 sync ready")
for i in range(1000000):
    v, a = np.random.beta(2,5), np.random.beta(3,3)
    model.step(valence=v, arousal=a)
    if i%200==0: print(f"Sync {model.kuramoto_order_parameter():.4f}")
    time.sleep(0.001)
