function [f g] = GradientFunctionR2v2(x, kx, kf, M, frequency_offset, x_positions, phi_x)
% Calculates objective function as
%
% abs( M - sum_j sum_p m_j  exp(-i2pi( x*kx + (delta_f + phi_x + R2/i2pi)*kf))
% 
% phi_x is assumed as correct, so only species and R2* are corrected.

if nargout == 1
    f = gfR2b(x,kx,kf,M,frequency_offset, x_positions, phi_x);
else
    [f,g] = gfR2b(x,kx,kf,M,frequency_offset, x_positions, phi_x);
end
return

Mspecies = numel(frequency_offset);
Nsamples = numel(x_positions);
N = Nsamples;

Nacq = size(kx,1);
m = zeros(Mspecies, Nsamples);

%phi_x = x(2*Mspecies*Nsamples+(1:N)).';

% R2 for fat is considered.
% R2_x = x(2*(Mspecies)*N+N+(1:N));
R2_x = zeros(Mspecies, N);
R2idx = 2;
R2_x(R2idx ,:) = x(2*(Mspecies)*N+N+(1:N)).';
R2_x(1,:) = x(2*(Mspecies)*N+N+(1:N)).';
% x(2*(Mspecies)*N+N+(1:N))

Mestimate = zeros(1, Nsamples*Nacq);
expon2 = zeros(N,N*Nacq,Mspecies);

TE = kf(:,N/2+1);

%sign_phi = 1;

midospi = -2i*pi; 

for jj = 1:Mspecies
    m(jj,:) = x((jj-1)*2*N + (1:N)) + ...
                1i*x((jj-1)*2*N + N + (1:N));
    expon2(:,:,jj) = exp(midospi.*(-kf(:)*(frequency_offset(jj) + phi_x.' + R2_x(1,:)./midospi)...
                                  + kx(:)*(x_positions))).';        
    Mestimate =  Mestimate + (m(jj,:)*expon2(:,:,jj));   
end

% f = sum(sum(abs(fft(M - Mestimate)).^2));
f = sum(abs(M(:) - Mestimate(:)).^2);

if nargout > 1 % gradient required
    g = zeros(size(x'));
    diff_m = (M(:) - Mestimate(:));
    for jj = 1:Mspecies   
        deriv_x   = expon2(:,:,jj);
        deriv_y   = 1i*deriv_x;
        deriv_R2 = (-(kf(:)*m(jj,:)).').*deriv_x;
%         g((1:2*N)+2*N*(jj-1)) = g((1:2*N)+2*N*(jj-1)) - [
%             (conj(deriv_x)*diff_m+deriv_x*conj(diff_m));
%             (conj(deriv_y)*diff_m+deriv_y*conj(diff_m))];
        g((1:2*N)+2*N*(jj-1)) = g((1:2*N)+2*N*(jj-1)) - [
            (diff_m.'*deriv_x'+diff_m'*deriv_x.'),(diff_m.'*deriv_y'+diff_m'*deriv_y.')].';
        g((1:N)+N+2*N*(Mspecies)) = g((1:N)+N+2*N*(Mspecies)) - ...
            (diff_m.'*deriv_R2'+diff_m'*deriv_R2.').';
    end
    %g = 2*g;
    %g((1:N)+2*N*(Mspecies)) = real(g((1:N)+2*N*(Mspecies))) + imag(g((1:N)+2*N*(Mspecies)));
end

% % Calculates objective function as
% %
% % abs( M - sum_j sum_p m  exp(-i2pi( x*kx + (delta_f + phi_x)*kf ) for Mspecies acquisitons
% % Mspecies = 
% %
% % Now m is complex
% %
% % x must be [(2*M + 1)*N 1]
% % The order is [spe1_real spe1_imag ... speM_real speM_imag phi_x]
% % Ms must be [1 N]
% % ks must be [1 N]
% % global kx kf M frequency_offset x_positions 
% 
% Mspecies = numel(frequency_offset);
% Nsamples = numel(x_positions);
% N = Nsamples;
% 
% Nacq = size(kx,1);
% m = zeros(Mspecies, Nsamples);
% 
% %phi_x = x(2*Mspecies*Nsamples+(1:N)).';
% 
% % R2 for fat is considered.
% % R2_x = x(2*(Mspecies)*N+N+(1:N));
% % R2_x = zeros(Mspecies, N);
% R2idx = 2;
% R2_x(R2idx ,:) = x(2*(Mspecies)*N+N+(1:N)).';
% % x(2*(Mspecies)*N+N+(1:N))
% 
% Mestimate = zeros(Nacq, Nsamples);
% expon2 = zeros(N,N,Mspecies,Nacq);
% 
% TE = kf(:,N/2+1);
% 
% %sign_phi = 1;
% 
% midospi = -2i*pi; 
% 
% for jj = 1:Mspecies
%     %initial_index = ((jj - 1)*2*Nsamples);
%     m(jj,:) = x(((jj-1)*2*N + 1):((jj-1)*2*N + N)) + ...
%                 1i*x(((jj-1)*2*N + N + 1):((jj-1)*2*N + 2*N));
%     for ii = 1:Nacq
%         expon2(:,:,jj,ii) = exp(midospi*(-(frequency_offset(jj) ...
%             + phi_x)*kf(ii,:) + x_positions'*kx(ii,:)));
%         Mestimate(ii,:) = Mestimate(ii,:) + (m(jj,:).*exp(-R2_x(jj,:)*TE(ii)))...
%                             *expon2(:,:,jj,ii);   
%     end
% end
% 
% f = sum(abs(M(:) - Mestimate(:)).^2);
% 
% if nargout > 1 % gradient required
%     g = zeros(size(x'));
%     for ii = 1:Nacq
%         diff_m = (M(ii,:) - Mestimate(ii,:)).';
%         for jj = 1:Mspecies          
%             deriv_x   = expon2(:,:,jj,ii);
%             deriv_y   = 1i*deriv_x;            
%              g((1:2*N)+2*N*(jj-1)) = g((1:2*N)+2*N*(jj-1)) - [
%                 (conj(deriv_x)*diff_m+deriv_x*conj(diff_m));
%                 (conj(deriv_y)*diff_m+deriv_y*conj(diff_m))];
%         end
%         % R2
%         deriv_R2 = expon2(:,:,R2idx,ii);
%         TEm = -TE(ii)*m(R2idx,:).';
%         g((1:N)+N+2*N*(Mspecies)) = g((1:N)+N+2*N*(Mspecies)) - ...
%                 (conj(deriv_R2)*(diff_m.*conj(TEm))...
%                + deriv_R2*(conj(diff_m).*TEm) );  
% %         deriv_R2 = repmat((-TE(ii)*m(R2idx,:)).',1,Nsamples).*expon2(:,:,R2idx,ii);
% %         g((1:N)+N+2*N*(Mspecies)) = g((1:N)+N+2*N*(Mspecies)) - ( ...
% %                 (diff_m.'*deriv_R2'+diff_m'*deriv_R2.').' );        
%     end
%     %g((1:N)+2*N*(Mspecies)) = real(g((1:N)+2*N*(Mspecies))) + imag(g((1:N)+2*N*(Mspecies)));
% end
