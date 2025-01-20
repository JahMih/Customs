--Snake-Eyes Execute Dragon
--Scripted by User
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon procedure
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsType,TYPE_TUNER),1,1,aux.FilterBoolFunctionEx(Card.IsType,TYPE_MONSTER),1,99)

	--Place a monster as a Continuous Spell (Quick Effect)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_LEAVE_GRAVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spellcon) -- Restrict to Main Phase and prevent reuse next turn
	e1:SetTarget(s.spelltg)
	e1:SetOperation(s.spellop)
	c:RegisterEffect(e1)

	-- Prevent reuse of "Place as Continuous Spell" next turn
	local e1b=Effect.CreateEffect(c)
	e1b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1b:SetCode(EVENT_TURN_END)
	e1b:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1b:SetCountLimit(1,{id,2}) 
	e1b:SetOperation(s.resetflag)
	Duel.RegisterEffect(e1b,0)

	--Destroy a monster and a Continuous Spell (Quick Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

-- Condition: Can only activate during the Main Phase and if not locked
function s.spellcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase() and Duel.GetFlagEffect(tp,id)==0
end

-- Select 1 face-up monster on the field AND 1 monster in the GY
function s.spelltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) 
		and Duel.IsExistingTarget(Card.IsType,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,TYPE_MONSTER) 
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g1=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g2=Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,TYPE_MONSTER)

	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g1,2,0,0)
end

-- Place both targets as Continuous Spells & lock effect for next turn
function s.spellop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	for tc in aux.Next(tg) do
		if tc and tc:IsRelateToEffect(e) then
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		end
	end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,2) -- Lock effect for next turn, resets after that
end

-- Reset the lock at the end of the opponent's turn after the next one
function s.resetflag(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFlagEffect(tp,id)>0 then
		Duel.ResetFlagEffect(tp,id)
	end
end

-- Select & Destroy 1 Monster & 1 Continuous Spell
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
		and Duel.IsExistingTarget(Card.IsType,tp,LOCATION_SZONE,LOCATION_SZONE,1,nil,TYPE_CONTINUOUS) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g2=Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_SZONE,LOCATION_SZONE,1,1,nil,TYPE_CONTINUOUS)
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,2,0,0)
end

-- Destroy selected Monster & Continuous Spell
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
