vec3 paving_normal(vec3 normal,vec3 position,float height){
	vec3 px=dFdx(position),py=dFdy(position);
	vec3 rx=cross(py,normal),ry=cross(normal,px);
	float determinant=dot(px,rx);
	if(abs(determinant)<1e-10){return normal;}
	return normalize(normal-(rx*dFdx(height)+ry*dFdy(height))/determinant);
}
